import { ScrollView, StyleSheet, Text } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { HallowedBackground } from "@/components/HallowedBackground";
import { HallowedCard } from "@/components/HallowedCard";
import { colors, spacing, type } from "@/design/tokens";
import { history } from "@/data/mock";

export default function HistoryScreen() {
  return (
    <HallowedBackground>
      <SafeAreaView style={styles.safe}>
        <ScrollView contentContainerStyle={styles.content}>
          <Text style={styles.title}>History</Text>
          {history.map((item) => (
            <HallowedCard key={item.id} style={styles.row}>
              <Text style={styles.rowTitle}>{item.title}</Text>
              <Text style={styles.meta}>{item.date} · {item.duration}</Text>
            </HallowedCard>
          ))}
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
    gap: spacing.md
  },
  title: {
    ...type.title,
    color: colors.text,
    marginBottom: spacing.sm
  },
  row: {
    gap: spacing.xs
  },
  rowTitle: {
    ...type.section,
    color: colors.text
  },
  meta: {
    ...type.caption,
    color: colors.muted
  }
});
