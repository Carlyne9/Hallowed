import { Pressable, StyleSheet, Text, ViewStyle } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { colors, radius, spacing, type } from "@/design/tokens";

type Props = {
  title: string;
  onPress?: () => void;
  style?: ViewStyle;
};

export function ActionButton({ title, onPress, style }: Props) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [style, pressed && styles.pressed]}>
      <LinearGradient colors={[colors.amber, colors.amberDeep]} style={styles.fill}>
        <Text style={styles.text}>{title}</Text>
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  fill: {
    minHeight: 54,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: radius.lg,
    paddingHorizontal: spacing.xl
  },
  text: {
    ...type.body,
    color: colors.text,
    fontWeight: "800"
  },
  pressed: {
    opacity: 0.82,
    transform: [{ scale: 0.99 }]
  }
});
