import { createClient } from "npm:@supabase/supabase-js@2";

// Deletes the signed-in user's account and all their data.
//
// The caller is identified only by the JWT the app sends; no user id is read
// from the body, so nobody can delete someone else's account. Avatars are
// removed from Storage first, then public.delete_account removes the user,
// their logs and, by cascade, everything else they own.

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json(405, { error: "Method not allowed" });
  }

  const jwt = (req.headers.get("Authorization") ?? "").replace(
    /^Bearer\s+/i,
    "",
  );
  if (!jwt) {
    return json(401, { error: "Unauthorized" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json(500, { error: "Supabase env variables are missing" });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: auth, error: authError } = await admin.auth.getUser(jwt);
  const userId = auth?.user?.id;
  if (authError || !userId) {
    return json(401, { error: "Unauthorized" });
  }

  // Avatars are stored as avatars/<user id>/avatar_<timestamp>.<ext>.
  const avatars = admin.storage.from("avatars");
  const { data: files, error: listError } = await avatars.list(userId, {
    limit: 1000,
  });
  if (listError) {
    return json(500, { error: "Could not list avatars" });
  }
  if (files && files.length > 0) {
    const { error: removeError } = await avatars.remove(
      files.map((f) => `${userId}/${f.name}`),
    );
    if (removeError) {
      return json(500, { error: "Could not remove avatars" });
    }
  }

  const { error: deleteError } = await admin.rpc("delete_account", {
    target: userId,
  });
  if (deleteError) {
    return json(500, { error: "Could not delete the account" });
  }

  return json(200, { deleted: true });
});
