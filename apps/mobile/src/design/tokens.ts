export const colors = {
  canvas: "#0D120F",
  panel: "#171D19",
  panelDeep: "#101511",
  glass: "rgba(255,255,255,0.075)",
  glassStrong: "rgba(255,255,255,0.12)",
  line: "rgba(255,255,255,0.12)",
  lineStrong: "rgba(255,255,255,0.22)",
  text: "#F6F0E6",
  muted: "#B7ADA0",
  faint: "#7E877E",
  amber: "#DCA13A",
  amberDeep: "#A76024",
  rose: "#D97765",
  success: "#83C47A",
  black: "#080A08"
} as const;

export const spacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 48
} as const;

export const radius = {
  sm: 10,
  md: 14,
  lg: 18,
  xl: 24,
  xxl: 32,
  full: 999
} as const;

export const type = {
  title: {
    fontSize: 36,
    lineHeight: 40,
    fontWeight: "700" as const
  },
  section: {
    fontSize: 20,
    lineHeight: 26,
    fontWeight: "700" as const
  },
  body: {
    fontSize: 16,
    lineHeight: 23,
    fontWeight: "500" as const
  },
  label: {
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "700" as const
  },
  caption: {
    fontSize: 12,
    lineHeight: 17,
    fontWeight: "500" as const
  }
} as const;
