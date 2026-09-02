// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment

import { createClient } from "npm:@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";

// Verify the caller sent the shared secret stored in Supabase secrets.
const internalKey = Deno.env.get("FCM_INTERNAL_KEY");
if (!internalKey) {
  throw new Error("FCM_INTERNAL_KEY secret is not set");
}

const serviceAccountRaw = Deno.env.get("FCM_SERVICE_ACCOUNT");
if (!serviceAccountRaw) {
  throw new Error("FCM_SERVICE_ACCOUNT secret is not set");
}

interface ServiceAccount {
  type: string;
  project_id: string;
  private_key: string;
  client_email: string;
  token_uri: string;
}

const serviceAccount: ServiceAccount = JSON.parse(serviceAccountRaw);

Deno.serve(async (req) => {
  const requestKey = req.headers.get("x-fcm-internal-key");
  if (requestKey !== internalKey) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { user_id, title, body, data } = await req.json() as {
    user_id: string;
    title: string;
    body: string;
    data?: Record<string, unknown>;
  };

  if (!user_id || !title || !body) {
    return new Response(
      JSON.stringify({ error: "Missing user_id, title or body" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !supabaseServiceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Supabase env variables are missing" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", user_id)
    .single();

  if (error || !profile?.fcm_token) {
    return new Response(
      JSON.stringify({ error: "Recipient not found or no fcm_token" }),
      { status: 404, headers: { "Content-Type": "application/json" } },
    );
  }

  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });

  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();
  if (!accessToken) {
    return new Response(
      JSON.stringify({ error: "Failed to get FCM access token" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const messagePayload: Record<string, unknown> = {
    message: {
      token: profile.fcm_token,
      notification: { title, body },
      data: data
        ? Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)]),
          )
        : {},
      android: {
        priority: "high",
        notification: {
          channel_id: "high_importance_channel",
          sound: "default",
        },
      },
    },
  };

  const fcmResponse = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(messagePayload),
    },
  );

  if (!fcmResponse.ok) {
    const errorText = await fcmResponse.text();
    return new Response(
      JSON.stringify({ error: "FCM request failed", details: errorText }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  }

  const fcmData = await fcmResponse.json();
  return new Response(JSON.stringify({ success: true, fcm: fcmData }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
