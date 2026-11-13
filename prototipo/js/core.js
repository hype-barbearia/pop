/* =========================================================
   Núcleo: dia simulado, horas e utilitários
   O protótipo vive em quinta, 12 de novembro de 2026.
   ========================================================= */
const DIA_LABEL = 'quinta-feira, 12 de novembro de 2026', DIA_CURTO = 'qui, 12/11';
const DAY_START = 8 * 60, DAY_END = 21 * 60;
const WEEK = ['dom','seg','ter','qua','qui','sex','sáb'];
const toMin = s => { const [h, m] = String(s).split(':').map(Number); return h * 60 + (m || 0); };
const hm = m => m == null ? '' : String(Math.floor(m / 60)).padStart(2, '0') + ':' + String(Math.round(m % 60)).padStart(2, '0');
const dayDate = back => new Date(2026, 10, 12 - back);
const dLabel = back => { const d = dayDate(back); return String(d.getDate()).padStart(2, '0') + '/' + String(d.getMonth() + 1).padStart(2, '0'); };

const $ = s => document.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const pct = (v, d = 0) => ((v || 0) * 100).toLocaleString('pt-BR', {minimumFractionDigits:d, maximumFractionDigits:d}) + '%';
const nf = (v, d = 0) => (v || 0).toLocaleString('pt-BR', {minimumFractionDigits:d, maximumFractionDigits:d});
const sum = (a, f = x => x) => a.reduce((t, x) => t + (f(x) || 0), 0);
const clone = o => JSON.parse(JSON.stringify(o));
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const firstName = n => String(n).split(' ')[0];
const initials = n => String(n).split(' ').map(x => x[0]).slice(0, 2).join('');
const mins = m => m < 60 ? `${Math.round(m)} min` : `${Math.floor(m / 60)}h${String(Math.round(m % 60)).padStart(2, '0')}`;
function rng(seed){ return () => (seed = (seed * 1664525 + 1013904223) % 4294967296) / 4294967296; }
