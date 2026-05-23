# Content Strategy

> Last updated: 2026-05-20 — full book analysis complete (46 chapters, all headings + scripture refs extracted)
> Responsible agent: `content-agent`
> Location: `shared/content/`

## Overview

All prayer and scripture content is pre-authored and curated. Content is seeded into Supabase via migration and cached locally on each device. Users cannot edit content — they can only pin/hide topics from the randomizer.

**Source reference**: The Flow Prayer Book (46 chapters) was used to identify prayer themes and topic structure. All prayer text in Hallowed is original — written in the same tradition but not copied from the book.

---

## Content Hierarchy

```
Prayer Theme
└── Prayer Topic (many per theme)
    └── Prayer (one or more per topic)
        └── Scripture Links (one or more per prayer, per translation)
```

---

## Prayer Themes (Final List — 23 Themes)

Updated 2026-05-20: 22 themes (Marriage merged into Family & Relationships). Minimum 10 topics per theme.

| # | Theme | Description | Icon (SF Symbol) | Color |
|---|-------|-------------|------------------|-------|
| 1 | Thanksgiving | Gratitude and praise to God | `hands.sparkles` | `#F59E0B` |
| 2 | The Holy Spirit | Praying for the Spirit's presence, gifts and power | `flame` | `#EF4444` |
| 3 | Intercession | Praying for others — people, nations, the Church | `person.2.wave.2` | `#3B82F6` |
| 4 | Confession & Repentance | Acknowledging sin, seeking forgiveness and cleansing | `arrow.uturn.backward.circle` | `#6366F1` |
| 5 | Worship & Adoration | Glorifying God for who He is | `sun.max` | `#EC4899` |
| 6 | Identity & Purpose | Who God made you to be; your calling and destiny | `person.crop.circle.badge.checkmark` | `#10B981` |
| 7 | Guidance & Wisdom | Seeking direction, revelation and the spirit of counsel | `map` | `#8B5CF6` |
| 8 | Spiritual Warfare | Standing against the enemy; binding and spiritual armor | `shield.lefthalf.filled` | `#DC2626` |
| 9 | Healing & Restoration | Physical, emotional and spiritual healing | `heart.circle` | `#06B6D4` |
| 10 | The Nations & Mission | Global church, evangelism, praying for the lost | `globe.americas` | `#F97316` |
| 11 | Family & Relationships | Children, community, friendship and extended family | `house.fill` | `#84CC16` |
| 12 | Ministry & Calling | Apostolic, prophetic and servant ministry | `briefcase` | `#A3A3A3` |
| 13 | Blessing & Fruitfulness | Receiving and releasing God's blessings | `leaf.arrow.circlepath` | `#D97706` |
| 14 | Lament | Honest grief and struggle brought before God | `cloud.rain` | `#78716C` |
| 15 | Love | God's love for us, loving God, and loving others | `heart.fill` | `#F43F5E` |
| 16 | Hope | Anchoring faith in God's promises through every season | `sunrise` | `#FBBF24` |
| 17 | Peace | The peace of God that surpasses understanding | `leaf` | `#34D399` |
| 18 | Fear & Anxiety | Overcoming fear, anxiety, worry and stress | `waveform.path` | `#818CF8` |
| 19 | Temptation | Standing firm against temptation and the desires of the flesh | `exclamationmark.triangle` | `#FB923C` |
| 20 | Trust | Surrendering to God's sovereignty and faithfulness | `lock.open.fill` | `#60A5FA` |
| 21 | Anger | Processing anger before God; choosing forgiveness | `flame.fill` | `#EF4444` |
| 22 | Pride | Choosing humility; surrendering self-sufficiency to God | `arrow.down.heart` | `#A78BFA` |
*(Marriage merged into Theme 11 — Family & Relationships)*

---

## Prayer Topics per Theme (Full List)

*Minimum 10 topics per theme. Each topic = 2 original prayers + 1–3 scriptures.*

### 1. Thanksgiving *(10 topics)*
- Gratitude for Creation
- Gratitude for Salvation
- Gratitude for Daily Provision
- Gratitude for Family and Friends
- Gratitude in Trials and Suffering
- Thanksgiving from the Psalms
- Gratitude for God's Faithfulness
- Gratitude for Answered Prayer
- Gratitude for Health and Strength
- Gratitude for God's Word

### 2. The Holy Spirit *(10 topics)*
- Inviting the Holy Spirit's Presence
- Prayer for the Gifts of the Holy Spirit
- Prayer for the Spirit to Come Upon You
- Walking in the Spirit Daily
- The Holy Spirit as Counsellor and Guide
- Praying in the Spirit
- The Fruit of the Holy Spirit
- Being Filled Afresh with the Spirit
- The Spirit's Power for Witness
- Sensitivity to the Voice of the Holy Spirit

### 3. Intercession *(10 topics)*
- Praying for Government and National Leaders
- Praying for the Persecuted Church
- Praying for the Lost
- Praying for Missionaries
- Praying for the Sick
- Praying for Your City
- Praying for God's Servants and Ministers
- Praying for the Church
- Praying for Israel and the Jewish People
- Praying for Your Workplace

### 4. Confession & Repentance *(10 topics)*
- Confessing Pride and Self-Reliance
- Confessing Unforgiveness
- Confessing Anxiety and Unbelief
- Confessing Neglect of God's Word
- Confessing Anger and Bitterness
- Confessing Idols and Competing Loves
- Seeking Forgiveness and Mercy
- Confessing Prayerlessness
- Confessing Ingratitude
- Repentance on Behalf of Your Nation

### 5. Worship & Adoration *(10 topics)*
- Worshipping God as Creator
- Worshipping Jesus as Lord
- Praise from the Psalms
- Declaring God's Attributes
- Adoration at the Start of the Day
- Worshipping Through Suffering
- Entering His Courts with Praise
- The Names of God in Worship
- Worshipping in Spirit and Truth
- Night Watch — Worshipping Before Sleep

### 6. Identity & Purpose *(10 topics)*
- Prayer Concerning Why You Were Created
- Becoming a Beloved Son or Daughter
- Removing Voids and Emptiness
- Praying against Confusion of Identity
- Walking in Your God-Given Purpose
- Prayer for a Renewed Mind
- You Are Chosen and Set Apart
- Your Identity in Christ (Ephesians 1)
- Breaking Off False Labels
- Living from Acceptance, Not for It

### 7. Guidance & Wisdom *(10 topics)*
- Prayer for the Spirit of Revelation
- Prayer for the Spirit of Counsel
- Prayer for Direction in Decisions
- Prayer for Discernment
- Prayer to be Led by the Spirit
- Prayer for Wisdom from Above
- Wisdom for Finances and Resources
- Guidance at a Crossroads
- When You Don't Know What to Do
- Wisdom in Relationships

### 8. Spiritual Warfare *(10 topics)*
- Putting on the Full Armour of God
- Binding Demonic Activity
- Prayer against Curses
- Standing against the Enemy's Schemes
- Praying the Blood of Jesus
- Pulling Down Strongholds
- Prayer for Angelic Intervention
- Stopping the Devil in His Tracks
- Warfare Prayer over Your Mind
- Warfare Prayer over Your Home

### 9. Healing & Restoration *(10 topics)*
- Prayer for Physical Healing
- Prayer for Emotional Healing
- Prayer for Inner Wounds to be Healed
- Restoration after Failure
- Prayer for a Broken Heart
- Healing of Memories
- Healing from Trauma
- Healing after Loss
- Restoration of What the Enemy Stole
- Healing in Broken Relationships

### 10. The Nations & Mission *(10 topics)*
- Praying for the Nations
- Prayer for Unreached People Groups
- Praying for Revival
- Prayer for Evangelists and Missionaries
- Praying for Your Nation's Spiritual Climate
- Prayer for the Harvest
- Praying for Africa
- Praying for the Middle East
- Praying for Asia
- Praying for Your Community's Transformation

### 11. Family & Relationships *(12 topics — includes Marriage)*
- Praying for Your Spouse by Name
- Building a Godly Home
- Prayer for Intimacy and Connection in Marriage
- Prayer through Conflict and Disagreement
- Protecting Your Marriage from the Enemy
- Prayer for Those Believing for a Spouse
- Prayer for Children
- Prayer for Prodigal Family Members
- Prayer for Friendship and Community
- Prayer for Divinely Appointed People in Your Life
- Prayer for Reconciliation
- Prayer for Extended Family

### 12. Ministry & Calling *(10 topics)*
- Prayer for Your Ministry and Assignment
- Prayer for Apostolic Ministry
- Prayer for the Prophetic
- Prayer to Fulfil Your Ministry
- Prayer to Become a Watchman
- Prayer for Those You Lead or Disciple
- Prayer for Your Workplace as a Ministry Field
- Prayer for New Doors in Ministry
- Prayer against Burnout in Ministry
- When Ministry Feels Fruitless

### 13. Blessing & Fruitfulness *(10 topics)*
- Prayer for the Blessings of Abraham
- Prayer for Fruitfulness in Every Season
- Prayer for the Blessings in Deuteronomy 28
- Prayer for a Fresh Anointing
- Prayer for Increase
- Prayer for Open Doors
- Blessing Your Children and Legacy
- Financial Blessing and Stewardship
- Fruitfulness in the Dry Season
- Breaking Generational Poverty

### 14. Lament *(10 topics)*
- When God Feels Distant
- Praying through Grief
- Honest Prayer in Times of Suffering
- When Prayer Feels Unanswered
- Wrestling with God Like Jacob
- Lament over Loss and Death
- When Your Dreams Have Died
- Crying Out from the Pit (Psalm 88)
- Lament for Injustice in the World
- Finding Beauty in Ashes

### 15. Love *(10 topics)*
- God's Love for You (1 John 4)
- Loving God with All Your Heart
- Loving Your Neighbour
- Loving Your Enemies
- Love as the Greatest Commandment
- When Love Feels Hard
- Rooted and Established in Love (Ephesians 3)
- Love That Never Fails (1 Corinthians 13)
- Loving the Unlovable
- When You Feel Unlovable

### 16. Hope *(10 topics)*
- Hope When Everything Feels Hopeless
- Anchoring Your Soul in God's Promises
- Hope in the Resurrection
- Waiting on God with Hope
- Hope for Your Future
- Passing Hope to the Next Generation
- Hope as an Anchor (Hebrews 6)
- Renewing Hope after Disappointment
- Praying Hope over Others
- Hope in the Midst of Sickness

### 17. Peace *(10 topics)*
- The Peace That Surpasses Understanding
- Peace in the Middle of the Storm
- Finding Rest in God
- Peace in Your Home
- Being a Peacemaker
- When Your Mind Won't Quiet Down
- Shalom — God's Complete Peace
- Peace with Your Past
- Peace before a Hard Conversation
- The God of Peace Crushing Satan (Romans 16:20)

### 18. Fear & Anxiety *(10 topics)*
- When You Are Overwhelmed by Fear
- Releasing Anxiety to God
- Prayer against Worry and Overthinking
- When the Future Feels Uncertain
- Fear of Failure
- Breaking Free from Stress
- Perfect Love Casting Out Fear
- Fear of Man — What Others Think
- Fear of Death
- Anxiety about Health and the Body

### 19. Temptation *(10 topics)*
- Standing Firm against Temptation
- Fleeing the Desires of the Flesh
- When You Have Already Fallen
- Prayer for Self-Control
- Temptation in Secret Places
- Breaking Cycles of Sin
- The Way of Escape (1 Corinthians 10:13)
- Temptation in Technology and Media
- When Temptation Comes Through Relationships
- Guarding Your Eyes and Mind

### 20. Trust *(10 topics)*
- Trusting God When You Don't Understand
- Surrendering Control to God
- Trusting God's Timing
- When God's Plan Doesn't Make Sense
- Leaning Not on Your Own Understanding (Proverbs 3:5)
- Trusting God after Betrayal
- Trusting God with Your Finances
- Trusting God with Those You Love
- When Trust Has Been Broken by People
- Faith as the Evidence of Things Unseen

### 21. Anger *(10 topics)*
- Bringing Your Anger to God Honestly
- Choosing Forgiveness over Resentment
- When You Are Angry at God
- Anger toward People Who Hurt You
- Releasing Bitterness
- Righteous Anger — Hating What God Hates
- Breaking the Cycle of Reactive Anger
- Anger in Your Family and Home
- When Anger Has Become a Habit
- Praying for Those Who Made You Angry

### 22. Pride *(10 topics)*
- Choosing Humility before God
- Surrendering Self-Sufficiency
- Pride in Achievement and Success
- The Danger of a Proud Heart
- Learning to Receive Help
- Walking Humbly with Your God (Micah 6:8)
- Pride in How Others See You
- Comparison and Envy
- Boasting in the Cross Alone (Galatians 6:14)
- When Pride Masquerades as Confidence

---

## Bible Translations

| Code | Name | Notes |
|------|------|-------|
| `NIV` | New International Version | Primary/default |
| `KJV` | King James Version | Traditional, fully public domain |
| `ESV` | English Standard Version | Popular evangelical |
| `NLT` | New Living Translation | Accessible, conversational |
| `MSG` | The Message | Paraphrase, devotional use |

Each scripture verse is stored as a separate row per translation. The app displays one translation at a time (user preference) but all are available.

**Default translation**: NIV (changeable in Settings).

---

## Seed File Structure

### `shared/content/themes.json`
```json
[
  {
    "id": "uuid-stable",
    "name": "Thanksgiving",
    "description": "Gratitude and praise to God",
    "icon": "hands.sparkles",
    "color_hex": "#F59E0B",
    "sort_order": 1
  }
]
```

### `shared/content/topics.json`
```json
[
  {
    "id": "uuid-stable",
    "theme_id": "ref to theme uuid",
    "title": "Gratitude for Creation",
    "description": "Praising God for the beauty and order of the natural world",
    "tags": ["nature", "creation", "praise"],
    "sort_order": 1
  }
]
```

### `shared/content/prayers.json`
```json
[
  {
    "id": "uuid-stable",
    "topic_id": "ref to topic uuid",
    "title": "A Prayer of Wonder",
    "body": "Lord God, Creator of all things...\n\n[Full prayer text here]",
    "author": null,
    "is_classic": false
  }
]
```

### `shared/content/scriptures.json`
```json
[
  {
    "id": "uuid-stable",
    "book": "Psalms",
    "chapter": 19,
    "verse_start": 1,
    "verse_end": 2,
    "translation": "NIV",
    "text": "The heavens declare the glory of God; the skies proclaim the work of his hands.",
    "reference": "Psalm 19:1 (NIV)"
  }
]
```

### `shared/content/scripture_links.json`
```json
[
  {
    "prayer_id": "ref to prayer uuid",
    "scripture_id": "ref to scripture uuid"
  }
]
```

---

## Randomizer Logic

The randomizer runs client-side:

1. Load all topics user has not hidden (`user_topic_preferences.pref != 'hidden'`)
2. Weight pinned topics 3× normal
3. Avoid repeating the last 3 topics shown
4. Select randomly from the weighted pool
5. From the selected topic, pick a random prayer
6. Return prayer + linked scriptures (user's preferred translation)

---

## Scripture Canon (Priority Books)

Analysis of all 46 chapters reveals the book's most-used scriptures. Our prayers should draw from these same wells — they are the backbone of this prayer tradition.

| Frequency | Book | Notes |
|-----------|------|-------|
| 181x | Psalms | The primary prayer book — foundation of almost every chapter |
| 81x | Genesis | Creation, calling, covenant, identity |
| 75x | Matthew | Jesus' ministry, authority, Kingdom |
| 74x | Isaiah | Prophecy, Spirit, healing, nations |
| 68x | John | Holy Spirit, truth, abiding in Christ |
| 66x | Daniel | Wisdom, warfare, revelation, national crises |
| 50x | Deuteronomy | Blessings, covenant, obedience |
| 50x | Luke | Spirit, prayer, mission |
| 39x | Revelation | End-times, worship, warfare |
| 33x | 1 Corinthians | Gifts of the Spirit, ministry |
| 28x | Numbers | Journey, provision, intercession |
| 25x | 2 Corinthians | Weakness, ministry, spiritual warfare |
| 23x | Exodus | Deliverance, intercession, God's presence |
| 23x | Acts | Holy Spirit, mission, power |
| 22x | Romans | Salvation, Spirit, intercession |
| 21x | Proverbs | Wisdom, counsel |
| 21x | Esther | Intercession, divine appointment, strategy |

**Key insight**: This book "prays the scriptures" — prayers are built directly around specific passages. Our original prayers should follow the same pattern: anchor each prayer in 1–3 specific verses, and let the prayer flow from what the scripture says.

---

## Content Authoring Guidelines

Voice and style informed by the Flow Prayer Book tradition — bold, scripture-anchored, Spirit-led, direct address to God.

- Second-person address to God ("Lord", "Father", "Holy Spirit", "Jesus")
- 150–400 words per prayer (2–5 min read-aloud)
- Anchor each prayer in 1–3 specific scriptures — "pray the scripture"
- Each prayer usable standalone — no assumed context
- End with "Amen" or a personal response invitation
- Broadly Christian — avoid narrow denominational language
- Reflect the book's tone: expectant, bold, covenant-aware, Spirit-dependent

---

## Seeding into Supabase

Content seed SQL is generated from the JSON files:
```
apps/backend/supabase/migrations/20260519000006_seed_content.sql
```

Use stable UUIDs (generated once, not random on re-seed).

---

## Status

- [x] Themes finalized — 22 themes (revised 2026-05-20, Marriage merged into Family)
- [x] Topics mapped — 222 topics across 22 themes (min. 10 per theme)
- [ ] Prayers written (target: 2 per topic = 444 prayers)
- [ ] Scriptures collected per translation (NIV, KJV, ESV, NLT, MSG)
- [ ] JSON seed files created
- [ ] SQL migration generated from JSON
- [ ] Seed applied to production Supabase
- [ ] Randomizer tested against seed data
