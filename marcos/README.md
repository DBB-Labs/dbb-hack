# marcos/ — catálogos de conformidad

Catálogos (JSON) del corpus propio de Felipe (~/Desktop/ISO), para mapear cada
hallazgo del pentest a su control formal. Son notas propias, NO los PDF oficiales
ISO (con copyright). El corpus completo (fichas, reglas, perfiles) vive en el
Escritorio; aquí solo están los catálogos que DBB-HACK usa para el mapeo.

- `iso27002-controles.json` — 93 controles ISO/IEC 27002:2022 (id, título, evidencia, procedimiento).
- `owasp-asvs.json` — 345 requisitos OWASP ASVS 5.0.0.
- `owasp-wstg.json` — 97 identificadores WSTG 4.2 (pruebas web).
- `owasp-riesgos.json` — catálogos de riesgo Web/API/LLM.
- `criterios-unificados.json` — 568 criterios cruzados ISO+OWASP+WCAG.
- `control-proceso.json` — control ↔ proceso.

## Uso
Al cerrar el informe, cada hallazgo lleva su control: p.ej.
`ISO A.8.3 (Restricción de acceso a la información)` + `ASVS V4.x` + `WSTG-ATHZ-xx`.
Una correspondencia temática NO demuestra equivalencia normativa (ver LEEME del corpus).
