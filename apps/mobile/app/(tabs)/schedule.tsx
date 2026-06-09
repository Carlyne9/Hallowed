import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { HallowedBackground } from "@/components/HallowedBackground";
import { HallowedCard } from "@/components/HallowedCard";
import { colors, radius, spacing, type } from "@/design/tokens";
import { periods } from "@/data/mock";

export default function ScheduleScreen() {
  return (
    <HallowedBackground>
      <SafeAreaView style={styles.safe}>
        <ScrollView contentContainerStyle={styles.content}>
          <View style={styles.header}>
            <Text style={styles.title}>Prayer Periods</Text>
            <Pressable style={styles.addButton}>
              <Ionicons name="add" color={colors.text} size={22} />
            </Pressable>
          </View>

          {periods.map((period) => (
            <HallowedCard key={period.id} style={styles.period}>
              <View>
                <Text style={styles.periodTitle}>{period.title}</Text>
                <Text style={styles.meta}>{period.time} · {period.duration}</Text>
              </View>
              <View style={styles.activeDot} />
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
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: spacing.sm
  },
  title: {
    ...type.title,
    color: colors.text
  },
  addButton: {
    width: 46,
    height: 46,
    borderRadius: radius.full,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: colors.glassStrong,
    borderWidth: 1,
    borderColor: colors.line
  },
  period: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between"
  },
  periodTitle: {
    ...type.section,
    color: colors.text
  },
  meta: {
    ...type.caption,
    color: colors.muted,
    marginTop: spacing.xs
  },
  activeDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: colors.success
  }
});
