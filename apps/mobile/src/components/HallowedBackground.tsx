import { LinearGradient } from "expo-linear-gradient";
import { PropsWithChildren } from "react";
import { StyleSheet, View } from "react-native";
import { colors } from "@/design/tokens";

export function HallowedBackground({ children }: PropsWithChildren) {
  return (
    <LinearGradient
      colors={[colors.canvas, "#151911", "#0E1518"]}
      locations={[0, 0.48, 1]}
      style={styles.root}
    >
      <View style={styles.glowOne} />
      <View style={styles.glowTwo} />
      {children}
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1
  },
  glowOne: {
    position: "absolute",
    width: 280,
    height: 280,
    borderRadius: 140,
    backgroundColor: "rgba(220, 161, 58, 0.16)",
    left: -90,
    top: 120
  },
  glowTwo: {
    position: "absolute",
    width: 360,
    height: 360,
    borderRadius: 180,
    backgroundColor: "rgba(86, 112, 132, 0.20)",
    right: -120,
    bottom: 160
  }
});
