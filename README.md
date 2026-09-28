# DBB-HACK

Kit interno de revisión de seguridad de DBB para apps Next.js + Supabase.
Lo corre Claude Code dentro de VS Code (gratis), guiado por playbooks adaptados de
Strix (Apache-2.0, ver NOTICE). Encuentra fallas **leyendo el código**; no explota en vivo.

## Uso
En VS Code, dentro del repo a revisar: `/dbb-hack`  (o `/dbb-hack <ruta>`).
Recon manual: `bash recon/mapear.sh <ruta-repo>`

## Estructura
- `metodologia.md` — las 5 fases del proceso.
- `playbooks/strix-source/` — manuales por tipo de falla (de Strix).
- `recon/mapear.sh` — mapea superficies de ataque.
- `informes-plantilla/informe.md` — formato del informe.

Los informes se guardan en `~/Documents/STRIX ANALISIS/<año>/<proyecto>/<mes>/`.

## Límite honesto
No reemplaza un pentest con explotación en vivo (eso lo hace Strix, de pago).
Para fallas de código visible (autorización, RLS, IDOR, lógica) es muy efectivo y $0.
