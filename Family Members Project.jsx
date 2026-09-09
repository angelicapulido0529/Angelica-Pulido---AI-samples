import React, { useState, useEffect, useRef } from "react";

const FAMILY = [
  { id: "grandfather", en: "Grandfather", es: "Abuelo", phon: "gránd-fá-der", icon: "👴", gen: "grandparent" },
  { id: "grandmother", en: "Grandmother", es: "Abuela", phon: "gránd-má-der", icon: "👵", gen: "grandparent" },
  { id: "uncle", en: "Uncle", es: "Tío", phon: "án-col", icon: "👨", gen: "parent" },
  { id: "father", en: "Father", es: "Padre", phon: "fá-der", icon: "👨", gen: "parent" },
  { id: "mother", en: "Mother", es: "Madre", phon: "má-der", icon: "👩", gen: "parent" },
  { id: "aunt", en: "Aunt", es: "Tía", phon: "ant", icon: "👩", gen: "parent" },
  { id: "brother", en: "Brother", es: "Hermano", phon: "bró-der", icon: "👦", gen: "sibling" },
  { id: "sister", en: "Sister", es: "Hermana", phon: "sís-ter", icon: "👧", gen: "sibling" },
  { id: "cousin", en: "Cousin", es: "Primo / Prima", phon: "cá-sin", icon: "🧑", gen: "sibling" },
  { id: "son", en: "Son", es: "Hijo", phon: "san", icon: "👦", gen: "child" },
  { id: "daughter", en: "Daughter", es: "Daughter", phon: "dó-ter", icon: "👧", gen: "child" },
  { id: "baby", en: "Baby", es: "Bebé", phon: "béi-bi", icon: "👶", gen: "child" },
];
// fix accidental duplicate spanish label
FAMILY[10].es = "Hija";

const ROWS = [
  { label: "Abuelos", ids: ["grandfather", "grandmother"] },
  { label: "Padres y tíos", ids: ["uncle", "father", "mother", "aunt"] },
  { label: "Hermanos y primos", ids: ["brother", "sister", "cousin"] },
  { label: "Hijos", ids: ["son", "daughter", "baby"] },
];

function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function speakWord(word) {
  try {
    if (typeof window === "undefined" || !window.speechSynthesis) return;
    window.speechSynthesis.cancel();
    const utter = new SpeechSynthesisUtterance(word);
    utter.lang = "en-US";
    utter.rate = 0.82;
    utter.pitch = 1.0;
    window.speechSynthesis.speak(utter);
  } catch (e) {
    // unsupported, ignore
  }
}

function buildDeck() {
  const chosen = shuffle(FAMILY).slice(0, 6);
  const cards = [];
  chosen.forEach((m) => {
    cards.push({ uid: `${m.id}-es`, familyId: m.id, kind: "es", member: m });
    cards.push({ uid: `${m.id}-en`, familyId: m.id, kind: "en", member: m });
  });
  return shuffle(cards);
}

function formatTime(sec) {
  const m = Math.floor(sec / 60)
    .toString()
    .padStart(2, "0");
  const s = (sec % 60).toString().padStart(2, "0");
  return `${m}:${s}`;
}

export default function FamilyAero() {
  const [mode, setMode] = useState("learn");
  const [selectedId, setSelectedId] = useState("father");

  const [deck, setDeck] = useState(buildDeck);
  const [flipped, setFlipped] = useState([]);
  const [matched, setMatched] = useState(new Set());
  const [moves, setMoves] = useState(0);
  const [locked, setLocked] = useState(false);
  const [seconds, setSeconds] = useState(0);
  const [running, setRunning] = useState(false);
  const timerRef = useRef(null);

  const selected = FAMILY.find((m) => m.id === selectedId);
  const won = matched.size === deck.length && deck.length > 0;

  useEffect(() => {
    if (mode === "play" && running && !won) {
      timerRef.current = setInterval(() => setSeconds((s) => s + 1), 1000);
      return () => clearInterval(timerRef.current);
    }
    return () => clearInterval(timerRef.current);
  }, [mode, running, won]);

  function startNewGame() {
    setDeck(buildDeck());
    setFlipped([]);
    setMatched(new Set());
    setMoves(0);
    setSeconds(0);
    setRunning(false);
    setLocked(false);
  }

  function handleCardClick(card) {
    if (locked || matched.has(card.uid) || flipped.includes(card.uid)) return;
    if (flipped.length >= 2) return;
    if (!running) setRunning(true);

    const next = [...flipped, card.uid];
    setFlipped(next);

    if (next.length === 2) {
      setMoves((m) => m + 1);
      const [firstUid, secondUid] = next;
      const first = deck.find((c) => c.uid === firstUid);
      const second = deck.find((c) => c.uid === secondUid);
      if (first.familyId === second.familyId) {
        speakWord(first.member.en);
        setTimeout(() => {
          setMatched((prev) => new Set(prev).add(firstUid).add(secondUid));
          setFlipped([]);
        }, 500);
      } else {
        setLocked(true);
        setTimeout(() => {
          setFlipped([]);
          setLocked(false);
        }, 950);
      }
    }
  }

  return (
    <div className="fa-root">
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Quicksand:wght@500;600;700&family=Nunito:wght@400;600;700;800&display=swap');

        .fa-root {
          --gray-100: #eef1f2;
          --gray-200: #dde2e5;
          --gray-300: #c3cad0;
          --gray-500: #8a939b;
          --gray-700: #4d555d;
          --gray-900: #2c3236;
          --green-200: #cdeab0;
          --green-400: #8fd464;
          --green-600: #4f9e42;
          --green-800: #2f6b2f;
          --sky-200: #cdeef0;
          position: relative;
          min-height: 100%;
          padding: 30px 18px 60px;
          background:
            radial-gradient(ellipse at 20% -10%, rgba(255,255,255,0.9), transparent 45%),
            radial-gradient(circle at 85% 10%, rgba(143,212,100,0.25), transparent 40%),
            radial-gradient(circle at 10% 90%, rgba(79,158,66,0.18), transparent 45%),
            linear-gradient(160deg, var(--gray-100) 0%, var(--gray-200) 45%, var(--gray-300) 100%);
          font-family: 'Nunito', sans-serif;
          color: var(--gray-900);
          overflow: hidden;
          box-sizing: border-box;
        }
        .fa-root *, .fa-root *::before, .fa-root *::after { box-sizing: border-box; }

        .fa-bubble {
          position: absolute;
          border-radius: 50%;
          background: radial-gradient(circle at 30% 25%, rgba(255,255,255,0.95), rgba(143,212,100,0.35) 55%, rgba(143,212,100,0.05) 100%);
          box-shadow: 0 6px 14px rgba(0,0,0,0.08);
          pointer-events: none;
          animation: fa-bob 5.5s ease-in-out infinite;
        }
        @keyframes fa-bob {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-16px); }
        }
        .fa-leaf {
          position: absolute;
          font-size: 1.4rem;
          opacity: 0.55;
          pointer-events: none;
          animation: fa-sway 4.5s ease-in-out infinite;
          filter: drop-shadow(0 3px 4px rgba(0,0,0,0.15));
        }
        @keyframes fa-sway {
          0%, 100% { transform: rotate(-8deg) translateY(0); }
          50% { transform: rotate(10deg) translateY(-8px); }
        }
        @media (prefers-reduced-motion: reduce) {
          .fa-bubble, .fa-leaf, .fa-hero, .fa-card-inner { animation: none !important; transition: none !important; }
        }

        .fa-hero {
          text-align: center;
          max-width: 640px;
          margin: 0 auto 20px;
          animation: fa-rise 0.7s ease-out;
        }
        @keyframes fa-rise {
          0% { transform: translateY(14px); opacity: 0; }
          100% { transform: translateY(0); opacity: 1; }
        }
        .fa-title {
          font-family: 'Quicksand', sans-serif;
          font-weight: 700;
          font-size: clamp(2.1rem, 6vw, 3.1rem);
          margin: 0;
          color: var(--gray-800, #3a4046);
          text-shadow: 0 2px 0 rgba(255,255,255,0.8), 0 10px 22px rgba(79,158,66,0.25);
        }
        .fa-title span {
          background: linear-gradient(160deg, var(--green-600), var(--green-800));
          -webkit-background-clip: text;
          background-clip: text;
          -webkit-text-fill-color: transparent;
        }
        .fa-subtitle {
          font-size: clamp(0.95rem, 2.2vw, 1.05rem);
          color: var(--gray-700);
          margin: 8px 0 0;
        }

        .fa-tabs {
          display: flex;
          justify-content: center;
          gap: 10px;
          margin: 22px auto 28px;
        }
        .fa-tab {
          font-family: 'Nunito', sans-serif;
          font-weight: 700;
          font-size: 0.92rem;
          padding: 10px 22px;
          border-radius: 999px;
          border: 1px solid rgba(255,255,255,0.7);
          cursor: pointer;
          color: var(--gray-700);
          background: linear-gradient(180deg, rgba(255,255,255,0.85), rgba(255,255,255,0.35));
          box-shadow: 0 3px 8px rgba(0,0,0,0.08), inset 0 1px 0 rgba(255,255,255,0.9);
          transition: transform 0.15s ease;
        }
        .fa-tab:hover { transform: translateY(-2px); }
        .fa-tab:focus-visible { outline: 2px solid var(--green-600); outline-offset: 2px; }
        .fa-tab.active {
          color: #fff;
          background: linear-gradient(180deg, var(--green-400), var(--green-700));
          border-color: transparent;
        }

        /* ---------- Learn: family tree ---------- */
        .fa-tree {
          max-width: 760px;
          margin: 0 auto;
        }
        .fa-row {
          margin-bottom: 26px;
        }
        .fa-row-label {
          text-align: center;
          font-size: 0.78rem;
          font-weight: 700;
          letter-spacing: 0.4px;
          color: var(--gray-500);
          margin-bottom: 10px;
        }
        .fa-nodes {
          display: flex;
          justify-content: center;
          gap: 18px;
          flex-wrap: wrap;
          position: relative;
        }
        .fa-node {
          width: 78px;
          border: none;
          background: none;
          cursor: pointer;
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 6px;
        }
        .fa-node-avatar {
          width: 62px;
          height: 62px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 1.7rem;
          background: linear-gradient(180deg, #ffffff, var(--gray-200));
          border: 2px solid rgba(255,255,255,0.9);
          box-shadow: 0 6px 14px rgba(0,0,0,0.12), inset 0 -4px 6px rgba(0,0,0,0.06);
          transition: transform 0.15s ease, box-shadow 0.2s ease;
        }
        .fa-node:hover .fa-node-avatar { transform: translateY(-3px); }
        .fa-node:focus-visible .fa-node-avatar { outline: 2px solid var(--green-600); outline-offset: 2px; }
        .fa-node.active .fa-node-avatar {
          background: linear-gradient(180deg, var(--green-200), var(--green-400));
          box-shadow: 0 8px 16px rgba(79,158,66,0.35), inset 0 -4px 6px rgba(0,0,0,0.08);
        }
        .fa-node-label {
          font-size: 0.74rem;
          font-weight: 700;
          color: var(--gray-700);
          text-align: center;
        }

        .fa-detail {
          max-width: 420px;
          margin: 8px auto 0;
          text-align: center;
          padding: 22px 24px 24px;
          border-radius: 26px;
          background: linear-gradient(160deg, rgba(255,255,255,0.85), rgba(255,255,255,0.45));
          backdrop-filter: blur(8px);
          border: 1px solid rgba(255,255,255,0.8);
          box-shadow: 0 14px 30px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.9);
        }
        .fa-detail-icon {
          font-size: 2.6rem;
          margin-bottom: 4px;
        }
        .fa-detail-en {
          font-family: 'Quicksand', sans-serif;
          font-weight: 700;
          font-size: 1.5rem;
          margin: 2px 0 0;
          color: var(--gray-900);
        }
        .fa-detail-es { color: var(--gray-500); font-size: 0.95rem; margin: 2px 0 6px; }
        .fa-detail-phon {
          font-family: 'Nunito', sans-serif;
          font-weight: 700;
          font-size: 1rem;
          color: var(--green-700, #3a7a34);
          margin: 0 0 14px;
        }
        .fa-speak {
          font-family: 'Nunito', sans-serif;
          font-weight: 700;
          font-size: 0.85rem;
          border: none;
          border-radius: 999px;
          padding: 10px 20px;
          cursor: pointer;
          color: #fff;
          background: linear-gradient(180deg, var(--green-400), var(--green-700));
          box-shadow: 0 6px 14px rgba(79,158,66,0.35);
        }
        .fa-speak:hover { filter: brightness(1.05); }
        .fa-speak:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }

        /* ---------- Play: memory match ---------- */
        .fa-play {
          max-width: 620px;
          margin: 0 auto;
          text-align: center;
        }
        .fa-statbar {
          display: flex;
          justify-content: center;
          gap: 14px;
          margin-bottom: 22px;
          flex-wrap: wrap;
        }
        .fa-statbox {
          background: linear-gradient(180deg, rgba(255,255,255,0.85), rgba(255,255,255,0.4));
          border: 1px solid rgba(255,255,255,0.8);
          border-radius: 14px;
          padding: 8px 18px;
          box-shadow: 0 4px 10px rgba(0,0,0,0.08);
        }
        .fa-statbox span { display: block; font-size: 0.7rem; color: var(--gray-500); font-weight: 700; }
        .fa-statval {
          font-family: 'Quicksand', sans-serif;
          font-weight: 700;
          font-size: 1.3rem;
          color: var(--green-700, #3a7a34);
        }

        .fa-board {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 12px;
          margin-bottom: 18px;
        }
        @media (max-width: 480px) {
          .fa-board { grid-template-columns: repeat(3, 1fr); }
        }

        .fa-card {
          background: none;
          border: none;
          padding: 0;
          cursor: pointer;
          aspect-ratio: 3 / 4;
          perspective: 800px;
        }
        .fa-card:disabled { cursor: default; }
        .fa-card:focus-visible .fa-card-inner { outline: 2px solid var(--green-600); outline-offset: 2px; }
        .fa-card-inner {
          position: relative;
          width: 100%;
          height: 100%;
          transition: transform 0.5s cubic-bezier(.3,.9,.4,1);
          transform-style: preserve-3d;
        }
        .fa-card.revealed .fa-card-inner { transform: rotateY(180deg); }

        .fa-card-face {
          position: absolute;
          inset: 0;
          border-radius: 16px;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          backface-visibility: hidden;
          padding: 6px;
        }
        .fa-card-back {
          background:
            radial-gradient(circle at 30% 20%, rgba(255,255,255,0.9), transparent 55%),
            linear-gradient(160deg, var(--gray-300), var(--gray-500));
          border: 1px solid rgba(255,255,255,0.6);
          box-shadow: 0 6px 12px rgba(0,0,0,0.12);
          font-size: 1.5rem;
        }
        .fa-card-front {
          background: linear-gradient(160deg, #ffffff, var(--green-200));
          border: 1px solid rgba(255,255,255,0.85);
          box-shadow: 0 6px 14px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.9);
          transform: rotateY(180deg);
          gap: 4px;
        }
        .fa-card.matched .fa-card-front {
          background: linear-gradient(160deg, var(--green-200), var(--green-400));
          box-shadow: 0 0 0 3px var(--green-600), 0 8px 16px rgba(79,158,66,0.3);
        }
        .fa-card-icon { font-size: 1.5rem; }
        .fa-card-word {
          font-family: 'Quicksand', sans-serif;
          font-weight: 700;
          font-size: 0.82rem;
          text-align: center;
          color: var(--gray-900);
          line-height: 1.15;
        }
        .fa-card-tag {
          font-size: 0.62rem;
          font-weight: 700;
          color: var(--gray-500);
          text-transform: none;
        }

        .fa-won {
          margin-top: 6px;
          padding: 18px;
          border-radius: 20px;
          background: linear-gradient(160deg, var(--green-200), var(--green-400));
          box-shadow: 0 10px 20px rgba(79,158,66,0.3);
        }
        .fa-won p {
          font-family: 'Quicksand', sans-serif;
          font-weight: 700;
          font-size: 1.1rem;
          margin: 0 0 12px;
          color: var(--gray-900);
        }
        .fa-again {
          font-family: 'Nunito', sans-serif;
          font-weight: 800;
          font-size: 0.95rem;
          border: none;
          border-radius: 999px;
          padding: 11px 26px;
          cursor: pointer;
          color: #fff;
          background: linear-gradient(180deg, var(--green-600), var(--green-800));
          box-shadow: 0 6px 14px rgba(47,107,47,0.4);
        }
        .fa-again:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }

        .fa-hint {
          text-align: center;
          font-size: 0.8rem;
          color: var(--gray-500);
          max-width: 480px;
          margin: 26px auto 0;
        }
      `}</style>

      <div className="fa-bubble" style={{ width: 60, height: 60, top: "6%", left: "6%" }} />
      <div className="fa-bubble" style={{ width: 34, height: 34, top: "16%", right: "10%", animationDelay: "1s" }} />
      <div className="fa-bubble" style={{ width: 44, height: 44, bottom: "10%", left: "10%", animationDelay: "2s" }} />
      <div className="fa-leaf" style={{ top: "10%", right: "20%" }}>🍃</div>
      <div className="fa-leaf" style={{ bottom: "16%", right: "8%", animationDelay: "1.4s" }}>🍃</div>

      <div className="fa-hero">
        <h1 className="fa-title">
          Family <span>Tree</span>
        </h1>
        <p className="fa-subtitle">Aprende a la familia en inglés y cómo se pronuncia</p>
      </div>

      <div className="fa-tabs">
        <button className={`fa-tab ${mode === "learn" ? "active" : ""}`} onClick={() => setMode("learn")}>
          🌿 Aprender
        </button>
        <button className={`fa-tab ${mode === "play" ? "active" : ""}`} onClick={() => setMode("play")}>
          🧩 Jugar
        </button>
      </div>

      {mode === "learn" && (
        <div className="fa-tree">
          {ROWS.map((row) => (
            <div className="fa-row" key={row.label}>
              <p className="fa-row-label">{row.label}</p>
              <div className="fa-nodes">
                {row.ids.map((id) => {
                  const m = FAMILY.find((f) => f.id === id);
                  return (
                    <button
                      key={id}
                      className={`fa-node ${selectedId === id ? "active" : ""}`}
                      onClick={() => setSelectedId(id)}
                    >
                      <span className="fa-node-avatar">{m.icon}</span>
                      <span className="fa-node-label">{m.es}</span>
                    </button>
                  );
                })}
              </div>
            </div>
          ))}

          {selected && (
            <div className="fa-detail">
              <div className="fa-detail-icon">{selected.icon}</div>
              <p className="fa-detail-en">{selected.en}</p>
              <p className="fa-detail-es">{selected.es}</p>
              <p className="fa-detail-phon">/{selected.phon}/</p>
              <button className="fa-speak" onClick={() => speakWord(selected.en)}>
                🔊 Escuchar
              </button>
            </div>
          )}
        </div>
      )}

      {mode === "play" && (
        <div className="fa-play">
          <div className="fa-statbar">
            <div className="fa-statbox">
              <span>Tiempo</span>
              <div className="fa-statval">{formatTime(seconds)}</div>
            </div>
            <div className="fa-statbox">
              <span>Movimientos</span>
              <div className="fa-statval">{moves}</div>
            </div>
            <div className="fa-statbox">
              <span>Parejas</span>
              <div className="fa-statval">{matched.size / 2} / {deck.length / 2}</div>
            </div>
          </div>

          <div className="fa-board">
            {deck.map((card) => {
              const revealed = matched.has(card.uid) || flipped.includes(card.uid);
              const isMatched = matched.has(card.uid);
              return (
                <button
                  key={card.uid}
                  className={`fa-card ${revealed ? "revealed" : ""} ${isMatched ? "matched" : ""}`}
                  onClick={() => handleCardClick(card)}
                  disabled={revealed}
                  aria-label={revealed ? (card.kind === "es" ? card.member.es : card.member.en) : "Carta oculta"}
                >
                  <div className="fa-card-inner">
                    <div className="fa-card-face fa-card-back">🍀</div>
                    <div className="fa-card-face fa-card-front">
                      <span className="fa-card-icon">{card.member.icon}</span>
                      <span className="fa-card-word">
                        {card.kind === "es" ? card.member.es : card.member.en}
                      </span>
                      <span className="fa-card-tag">{card.kind === "es" ? "ES" : "EN"}</span>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>

          {won && (
            <div className="fa-won">
              <p>
                ¡Completaste el árbol familiar! 🌳 {formatTime(seconds)} · {moves} movimientos
              </p>
              <button className="fa-again" onClick={startNewGame}>
                Jugar de nuevo
              </button>
            </div>
          )}

          {!won && (
            <button className="fa-again" onClick={startNewGame} style={{ marginTop: 4 }}>
              Reiniciar juego
            </button>
          )}
        </div>
      )}

      <p className="fa-hint">
        Consejo: en el juego, empareja la tarjeta en español con su pareja en inglés. Al
        acertar escucharás la pronunciación real.
      </p>
    </div>
  );
}
