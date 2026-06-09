import { ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { HallowedBackground } from "@/components/HallowedBackground";
import { HallowedCard } from "@/components/HallowedCard";
import { colors, spacing, type } from "@/design/tokens";

export default function SettingsScreen() {
  return (
    <HallowedBackground>
      <SafeAreaView style={styles.safe}>
        <ScrollView contentContainerStyle={styles.content}>
          <View style={styles.profile}>
            <View style={styles.avatar} />
            <View>
              <Text style={styles.name}>Carlyne Kets</Text>
              <Text style={styles.email}>carlynekets@gmail.com</Text>
            </View>
          </View>

          <HallowedCard style={styles.card}>
            <Text style={styles.sectionTitle}>Preferences</Text>
            <Text style={styles.row}>Language · English</Text>
            <Text style={styles.row}>Bible Version · NIV</Text>
            <Text style={styles.row}>Theme · Auto</Text>
          </HallowedCard>

          <HallowedCard style={styles.card}>
            <Text style={styles.sectionTitle}>Achievements</Text>
            <Text style={styles.row}>First Amen · Three-Day Flame · Faithful Flow</Text>
          </HallowedCard>
        </ScrollView>
      </SafeAreaView>
    </HallowedBackground>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1
  },
  content: {
    padding: spacing.xl,
    gap: spacing.lg
  },
  profile: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing.md,
    paddingTop: spacing.md
  },
  avatar: {
    width: 58,
    height: 58,
    borderRadius: 29,
    backgroundColor: colors.amber
  },
  name: {
    ...type.section,
    color: colors.text
  },
  email: {
    ...type.caption,
    color: colors.muted
  },
  card: {
    gap: spacing.md
  },
  sectionTitle: {
    ...type.label,
    color: colors.faint,
    textTransform: "uppercase",
    letterSpacing: 1
  },
  row: {
    ...type.body,
    color: colors.text
  }
});
