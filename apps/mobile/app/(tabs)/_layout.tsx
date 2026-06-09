import { Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { ColorValue } from "react-native";
import { colors } from "@/design/tokens";

type TabIconName = React.ComponentProps<typeof Ionicons>["name"];

function tabIcon(name: TabIconName) {
  return ({ color, size }: { color: ColorValue; size: number }) => (
    <Ionicons name={name} color={color as string} size={size} />
  );
}

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.amber,
        tabBarInactiveTintColor: colors.faint,
        tabBarStyle: {
          backgroundColor: colors.panel,
          borderTopColor: colors.line,
          minHeight: 74,
          paddingTop: 8
        },
        tabBarLabelStyle: {
          fontWeight: "700"
        }
      }}
    >
      <Tabs.Screen name="index" options={{ title: "Home", tabBarIcon: tabIcon("home-outline") }} />
      <Tabs.Screen name="library" options={{ title: "Themes", tabBarIcon: tabIcon("library-outline") }} />
      <Tabs.Screen name="schedule" options={{ title: "Periods", tabBarIcon: tabIcon("notifications-outline") }} />
      <Tabs.Screen name="history" options={{ title: "History", tabBarIcon: tabIcon("bar-chart-outline") }} />
      <Tabs.Screen name="settings" options={{ title: "Profile", tabBarIcon: tabIcon("person-circle-outline") }} />
    </Tabs>
  );
}
