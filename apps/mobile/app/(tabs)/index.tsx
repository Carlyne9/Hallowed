import { Link } from "expo-router";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { ActionButton } from "@/components/ActionButton";
import { HallowedBackground } from "@/components/HallowedBackground";
import { HallowedCard } from "@/components/HallowedCard";
import { colors, spacing, type } from "@/design/tokens";
import { periods } from "@/data/mock";

export default function HomeScreen() {
  return (
    <HallowedBackground>
      <SafeAreaView style={styles.safe}>
        <ScrollView contentContainerStyle={styles.content}>
          <View style={styles.header}>
            <Text style={styles.kicker}>Today</Text>
            <Text style={styles.title}>Peace be with you.</Text>
          </View>

          <HallowedCard style={styles.hero}>
            <Text style={styles.cardLabel}>Next prayer</Text>
            <Text style={styles.cardTitle}>{periods[0].title}</Text>
            <Text style={styles.meta}>{periods[0].time} · {periods[0].duration}</Text>
            <Link href="/prayer-session" asChild>
              <ActionButton title="Pray Now" style={styles.action} />
            </Link>
          </HallowedCard>

          <HallowedCard style={styles.scripture}>
            <Text style={styles.cardLabel}>Today's verse</Text>
            <Text style={styles.verse}>
              “Be still, and know that I am God.”
            </Text>
            <Text style={styles.reference}>Psalm 46:10</Text>
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
  header: {
    gap: spacing.xs,
    paddingTop: spacing.md
  },
  kicker: {
    ...type.label,
    color: colors.amber,
    textTransform: "uppercase",
    letterSpacing: 1.2
  },
  title: {
    ...type.title,
    color: colors.text
  },
  hero: {
    gap: spacing.sm
  },
  cardLabel: {
    ...type.label,
    color: colors.faint,
    textTransform: "uppercase",
    letterSpacing: 1
  },
  cardTitle: {
    ...type.section,
    color: colors.text
  },
  meta: {
    ...type.body,
    color: colors.muted
  },
  action: {
    marginTop: spacing.md
  },
  scripture: {
    gap: spacing.sm
  },
  verse: {
    ...type.body,
    color: colors.text
  },
  reference: {
    ...type.caption,
    color: colors.amber
  }
});
