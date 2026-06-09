import { FlatList, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { HallowedBackground } from "@/components/HallowedBackground";
import { HallowedCard } from "@/components/HallowedCard";
import { colors, spacing, type } from "@/design/tokens";
import { themeCards } from "@/data/mock";

export default function LibraryScreen() {
  return (
    <HallowedBackground>
      <SafeAreaView style={styles.safe}>
        <View style={styles.content}>
          <Text style={styles.title}>Prayer Themes</Text>
          <Text style={styles.copy}>Browse the curated library and choose a focus for prayer.</Text>

          <FlatList
            data={themeCards}
            keyExtractor={(item) => item.id}
            contentContainerStyle={styles.list}
            renderItem={({ item }) => (
              <HallowedCard style={styles.card}>
                <View style={styles.illustration} />
                <View style={styles.cardCopy}>
                  <Text style={styles.cardTitle}>{item.name}</Text>
                  <Text style={styles.cardDetail}>{item.detail}</Text>
                </View>
              </HallowedCard>
            )}
          />
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
    padding: spacing.xl,
    gap: spacing.sm
  },
  title: {
    ...type.title,
    color: colors.text
  },
  copy: {
    ...type.body,
    color: colors.muted
  },
  list: {
    gap: spacing.md,
    paddingTop: spacing.lg,
    paddingBottom: spacing.xxl
  },
  card: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing.md
  },
  illustration: {
    width: 64,
    height: 64,
    borderRadius: 22,
    backgroundColor: "rgba(220, 161, 58, 0.18)",
    borderWidth: 1,
    borderColor: colors.lineStrong
  },
  cardCopy: {
    flex: 1,
    gap: spacing.xs
  },
  cardTitle: {
    ...type.section,
    color: colors.text
  },
  cardDetail: {
    ...type.caption,
    color: colors.muted
  }
});
