import type { Config } from "tailwindcss";
const config: Config = { content:["./app/**/*.{ts,tsx}","./components/**/*.{ts,tsx}"], theme:{extend:{colors:{health:{50:"#effcf6",100:"#d9fbe8",600:"#059669",700:"#047857"}}}}, plugins:[] };
export default config;
