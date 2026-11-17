import { createClient } from "npm:@supabase/supabase-js@2";

const validLevels = new Set([
  "trace",
  "debug",
  "info",
  "warning",
  "error",
  "fatal",
]);

Deno.serve(async (req) => {
  const requestKey = req.headers.get("x-logs-key");
  const expectedKey = Deno.env.get("LOGS_API_KEY");
  if (!expectedKey || requestKey !== expectedKey) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body;
  try {
    body = (await req.json()) as { logs?: Array<Record<string, any>> };
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const logs = body.logs;
  if (!Array.isArray(logs)) {
    return new Response(
      JSON.stringify({ error: "Missing or invalid logs array" }),
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

  const records = logs.map((log: Record<string, any>) => {
    const level = validLevels.has(log?.level) ? log.level : "info";
    const message = typeof log?.message === "string" ? log.message : "(empty)";
    const now = new Date().toISOString();
    return {
      trace_id: log?.trace_id ?? null,
      level,
      message,
      data: log?.data ?? null,
      device_os: log?.device_os ?? null,
      device_model: log?.device_model ?? null,
      device_version: log?.device_version ?? null,
      app_version: log?.app_version ?? null,
      user_id: log?.user_id ?? null,
      created_at: log?.created_at ?? now,
    };
  });

  let { error } = await supabase.from("logs").insert(records);

  // A device can still send logs for a user who was just deleted (it flushes
  // its buffer after the account is gone). Keep the logs, without the user.
  if (error?.code === "23503") {
    ({ error } = await supabase
      .from("logs")
      .insert(records.map((r) => ({ ...r, user_id: null }))));
  }

  if (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({ success: true, count: records.length }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
