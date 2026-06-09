import { Link } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { HallowedBackground } from "@/components/HallowedBackground";
import { colors, radius, spacing, type } from "@/design/tokens";

export default function PrayerSessionScreen() {
  return (
    <HallowedBackground>
      <SafeAreaView style={styles.safe}>
        <View style={styles.top}>
          <Text style={styles.step}>Point 1/3</Text>
          <Text style={styles.timer}>14:32</Text>
        </View>

        <View style={styles.center}>
          <Text style={styles.theme}>Thanksgiving</Text>
          <Text style={styles.title}>Lord of Every Living Thing</Text>
          <Text style={styles.prayer}>
            Father, open my eyes to see Your fingerprints in ordinary gifts: warmth,
            breath, rain, mercy, and the quiet grace that keeps finding me.
          </Text>
          <Text style={styles.scripture}>Psalm 104:24</Text>
        </View>

        <Link href="/(tabs)" asChild>
          <Pressable style={styles.amen}>
            <Text style={styles.amenText}>Amen</Text>
          </Pressable>
        </Link>
      </SafeAreaView>
    </HallowedBackground>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    padding: spacing.xl
  },
  top: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between"
  },
  step: {
    ...type.caption,
    color: colors.faint
  },
  timer: {
    ...type.section,
    color: colors.text
  },
  center: {
    flex: 1,
    justifyContent: "center",
    gap: spacing.md
  },
  theme: {
    ...type.label,
    color: colors.amber,
    textTransform: "uppercase",
    letterSpacing: 1.4
  },
  title: {
    ...type.title,
    color: colors.text
  },
  prayer: {
    fontSize: 21,
    lineHeight: 32,
    color: colors.text
  },
  scripture: {
    ...type.body,
    color: colors.muted
  },
  amen: {
    minHeight: 56,
    borderRadius: radius.lg,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: colors.amber
  },
  amenText: {
    ...type.body,
    color: colors.text,
    fontWeight: "800"
  }
});
