# TÍTULO

Me construí mi propio hacker para atacar mi fintech (y lo regalo) 🤖🔓

---

# POST

¿Mi fintech es segura? 🔒 Me construí mi propio hacker. 🤖

En Kapa21 movemos plata de verdad 💰. Y yo no me quería quedar con el "debería estar ok". Quería saber, la firme, si aguantaba un ataque.

Partí probando la herramienta estrella de pentest con IA. Buena, sí. Pero te cobra por token y se me caía sola por los límites del proveedor. US$3,5 tirados en corridas que ni terminaron. Cero. Nada. 😤

Así que hice lo de siempre: no comprar, construir. 🛠️

Y nació DBB-HACK ⚡. Un pentester con su propio centro de comando (miren las fotos 👇). Gratis, con los manuales que usa la industria de verdad (OWASP, ISO 27002), en 4 niveles. Del escaneo básico hasta el modo BAMF, que ataca en vivo.

Lo apunté a Kapa21. Se montó solo un laboratorio aislado y le entró a combos 🎯. El marcador: 14 vectores, 12 defendidos, 2 hallazgos, 0 vulnerables. Robo de datos por fuera, escalada de privilegios, un operador moviendo plata sin segundo factor, webhook falso, fuerza bruta. Todo abajo. Con prueba, no con fe.

Y lo que más me gusta 🚀: cada hallazgo te llega con el prompt de arreglo listo para copiar. Ves el problema y lo despachas ahí mismo.

La regla que me puse: cero falsos positivos. Si no puede probar algo de verdad, dice "no probado" y punto. Nunca se inventa un "vulnerable" para verse útil. Porque si me miento a mí mismo, ¿qué le voy a decir a un cliente?

Ojo, esto no reemplaza un pentest profesional externo. Pero es una capa real, gratis y que corre siempre, que antes no tenía. 🛡️

👇 Miren la consola trabajando. ¿Su proyecto pasaría los 14 vectores?

---

# CÓMO INSTALARLO

Necesitas [Claude Code](https://claude.com/claude-code) (gratis, corre local — por eso DBB-HACK no cobra por token) y Docker.

```bash
git clone https://github.com/DBB-Labs/dbb-hack.git
cd dbb-hack
bash dashboard/servir.sh
```

Se abre la consola en `http://localhost:8899`. Eliges el repo objetivo (cualquier proyecto
Next.js + Supabase que tengas en tu máquina), el nivel (LOW/MID/FULL/BAMF) y los vectores, y
le das LANZAR. En FULL/BAMF el propio DBB-HACK monta el laboratorio aislado — no toca producción.

📦 Descarga / código fuente: **https://github.com/DBB-Labs/dbb-hack**
📖 Licencia GNU AGPL-3.0 — es open source, úsalo, cópialo, mejóralo.

---

# ¿TE SIRVIÓ?

Si esto te ahorró una plata en pentest o simplemente te dio paz mental, invítame un café ☕
👉 **https://buymeacoffee.com/DbbLabs**
