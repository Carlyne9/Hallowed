import { StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { ActionButton } from "@/components/ActionButton";
import { HallowedBackground } from "@/components/HallowedBackground";
import { HallowedCard } from "@/components/HallowedCard";
import { colors, spacing, type } from "@/design/tokens";

export default function SignInScreen() {
  return (
    <HallowedBackground>
      <SafeAreaView style={styles.safe}>
        <View style={styles.content}>
          <Text style={styles.brand}>Hallowed</Text>
          <Text style={styles.title}>Make room for prayer.</Text>
          <Text style={styles.copy}>
            Sign in to keep your prayer periods, themes, and history synced across your devices.
          </Text>

          <HallowedCard style={styles.card}>
            <ActionButton title="Continue with Google" />
            <Text style={styles.helper}>Magic link and Apple Sign In can be added after the core mobile flow is stable.</Text>
          </HallowedCard>
        </View>
      </SafeAreaView>
    </HallowedBackground>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1
  },
  content: {
    flex: 1,
    justifyContent: "center",
    padding: spacing.xl,
    gap: spacing.lg
  },
  brand: {
    ...type.label,
    color: colors.amber,
    textTransform: "uppercase",
    letterSpacing: 1.8
  },
  title: {
    ...type.title,
    color: colors.text
  },
  copy: {
    ...type.body,
    color: colors.muted
  },
  card: {
    gap: spacing.md
  },
  helper: {
    ...type.caption,
    color: colors.faint,
    textAlign: "center"
  }
});
