#!/usr/bin/env bash
# DBB-HACK recon: mapea las superficies de ataque de un repo Next.js + Supabase.
# Uso: mapear.sh <ruta-repo>   (imprime a stdout; redirige a un archivo si quieres)
set -euo pipefail
REPO="${1:?uso: mapear.sh <ruta-repo>}"
cd "$REPO"
SRC="."; [ -d src ] && SRC="src"

line(){ printf '\n== %s ==\n' "$1"; }

echo "# RECON DBB-HACK — $(basename "$REPO")  ($(date +%F))"
echo "raíz de código: $SRC"

line "Server Actions ('use server')"
grep -rln "use server" "$SRC" --include=*.ts --include=*.tsx 2>/dev/null | sort | sed 's/^/  /' || echo "  (ninguno)"

line "Route handlers (app/**/route.ts[x])"
find "$SRC" -type f \( -name 'route.ts' -o -name 'route.tsx' \) 2>/dev/null | sort | sed 's/^/  /' || echo "  (ninguno)"

line "Uso de service_role / clave secreta (NO debe estar en cliente)"
grep -rln -E "SERVICE_ROLE|service_role|SUPABASE_SECRET" "$SRC" --include=*.ts --include=*.tsx 2>/dev/null | sort | sed 's/^/  /' || echo "  (ninguno)"

line "Llamadas a Supabase RPC (.rpc()) y tablas (.from())"
grep -rhoE "\.(rpc|from)\(['\"][^'\"]+['\"]\)" "$SRC" --include=*.ts --include=*.tsx 2>/dev/null | sort | uniq -c | sort -rn | head -40 | sed 's/^/  /' || echo "  (ninguno)"

line "Políticas RLS y GRANT en migraciones"
grep -rlnE "enable row level security|create policy|grant |revoke |security definer" supabase/migrations 2>/dev/null | sort | sed 's/^/  /' || echo "  (sin migraciones)"

line "Funciones SECURITY DEFINER (revisar search_path)"
grep -rnE "security definer" supabase/migrations 2>/dev/null | sed 's/^/  /' || echo "  (ninguna)"

line "Tablas SIN 'enable row level security' aparente"
if [ -d supabase/migrations ]; then
  grep -rhoE "create table [a-z_.\"]+" supabase/migrations 2>/dev/null | awk '{print $3}' | tr -d '"' | sort -u | sed 's/^/  tabla: /' || true
  echo "  (contrastar contra las que sí tienen 'enable row level security')"
fi

line "Chequeos de rol/admin en el código (¿existen?)"
grep -rnoE "role *[=!]==? *['\"](admin|supervisor|socio|owner)['\"]|isAdmin|assertAdmin|requireRole|esAdmin|verificarRol" "$SRC" --include=*.ts --include=*.tsx 2>/dev/null | head -30 | sed 's/^/  /' || echo "  (NINGUNO — señal de alerta)"

line "Lectura de rol desde el cliente (user_metadata / claims — riesgo si se confía)"
grep -rnoE "user_metadata|app_metadata|raw_user_meta|jwt.*role|claims" "$SRC" --include=*.ts --include=*.tsx 2>/dev/null | head -20 | sed 's/^/  /' || echo "  (ninguno)"

line "Middleware"
find "$SRC" -maxdepth 2 -name 'middleware.ts' 2>/dev/null | sed 's/^/  /' || echo "  (sin middleware)"

echo -e "\n# fin del recon"
