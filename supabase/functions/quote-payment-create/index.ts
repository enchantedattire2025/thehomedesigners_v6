const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve((req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 200, headers: corsHeaders });
  return new Response(
    JSON.stringify({ error: "This endpoint is retired. Quote advance payments use payment-checkout." }),
    { status: 410, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
