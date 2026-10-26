import Foundation

/// Learn 页的三个分类。每个分类有一篇置顶课程和若干编号课程。
/// 所有课程文案均为草稿，上线前需临床审核；只做一般性教育，不做诊断或效果承诺。
enum LearnCategory: String, CaseIterable, Identifiable {
    case basics
    case howTo
    case mistakes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basics: "Basics"
        case .howTo: "How to"
        case .mistakes: "Common Mistakes"
        }
    }

    /// 大字号时分类标签空间不够，使用短标题。
    var shortTitle: String { self == .mistakes ? "Mistakes" : title }

    var featured: LearnLesson {
        switch self {
        case .basics: LearnLibrary.whereIsPelvicFloor
        case .howTo: LearnLibrary.firstSession
        case .mistakes: LearnLibrary.whyTechniqueMatters
        }
    }

    var lessons: [LearnLesson] {
        switch self {
        case .basics: LearnLibrary.basics
        case .howTo: LearnLibrary.howTo
        case .mistakes: LearnLibrary.mistakes
        }
    }

    /// 置顶课程在前，然后是编号课程，用于“下一课”。
    var readingOrder: [LearnLesson] { [featured] + lessons }
}

struct LearnLesson: Identifiable, Hashable {
    enum Art: Hashable {
        case pelvicDiagram
        case rhythm
        case symbol(String)
    }

    struct Section: Hashable {
        let heading: String
        let body: String
    }

    let id: String
    let category: LearnCategory
    var number: Int? = nil
    let title: String
    let summary: String
    let systemImage: String
    let minutes: Int
    var art: Art
    let sections: [Section]
    let keyPoints: [String]

    var numberedTitle: String { number.map { "\($0). \(title)" } ?? title }

    var next: LearnLesson? {
        let order = category.readingOrder
        guard let index = order.firstIndex(of: self), index + 1 < order.count else { return nil }
        return order[index + 1]
    }
}

enum LearnLibrary {
    static var all: [LearnLesson] { LearnCategory.allCases.flatMap(\.readingOrder) }

    static func lesson(id: String) -> LearnLesson? { all.first { $0.id == id } }

    // MARK: - Basics

    static let whereIsPelvicFloor = LearnLesson(
        id: "where", category: .basics,
        title: "Where is the pelvic floor?",
        summary: "Your pelvic floor muscles support the bladder, bowel and sexual function. Learn what they are and why they matter.",
        systemImage: "figure.stand", minutes: 3, art: .pelvicDiagram,
        sections: [
            .init(heading: "A sling at the base of your pelvis",
                  body: "The pelvic floor is a group of muscles that stretches like a hammock from the pubic bone at the front to the tailbone at the back. It sits underneath the bladder, the prostate and the bowel."),
            .init(heading: "What it supports",
                  body: "These muscles help hold the pelvic organs in place, help you control when you pass urine and wind, and are involved in sexual function."),
            .init(heading: "Why it's hard to feel",
                  body: "You can't see these muscles, and many people have never tried to move them on purpose. It is normal if they feel hard to find at first."),
        ],
        keyPoints: [
            "The pelvic floor sits between the pubic bone and the tailbone.",
            "It supports the bladder, bowel and prostate.",
            "Feeling unsure at first is common.",
        ]
    )

    static let basics: [LearnLesson] = [
        LearnLesson(
            id: "what", category: .basics, number: 1,
            title: "What is the pelvic floor?",
            summary: "Understand the muscles and their functions.",
            systemImage: "book", minutes: 3, art: .symbol("book.fill"),
            sections: [
                .init(heading: "Layers of muscle",
                      body: "The pelvic floor is made of several layers of muscle and connective tissue. Together they form a supportive base for the organs in your lower abdomen."),
                .init(heading: "Two jobs: tighten and let go",
                      body: "Like other muscles, the pelvic floor needs to be able to tighten when needed and relax completely afterwards. Both parts matter for comfortable everyday function."),
                .init(heading: "Working with your breathing",
                      body: "The pelvic floor moves gently with your breath. It lowers slightly as you breathe in and rises slightly as you breathe out."),
            ],
            keyPoints: [
                "The pelvic floor is a group of muscles, not a single one.",
                "Relaxing is as important as tightening.",
                "It moves naturally with your breathing.",
            ]
        ),
        LearnLesson(
            id: "contract", category: .basics, number: 2,
            title: "How to contract correctly",
            summary: "Learn how to find and activate the right muscles.",
            systemImage: "dumbbell", minutes: 4, art: .symbol("arrow.up.circle.fill"),
            sections: [
                .init(heading: "Find the muscles",
                      body: "Imagine you are trying to stop yourself passing wind, or gently lifting the area between your scrotum and back passage. That inward and upward lift is the movement you're looking for."),
                .init(heading: "Keep it gentle",
                      body: "A correct contraction is a small, controlled lift. You shouldn't see big movements elsewhere in your body."),
                .init(heading: "Keep everything else soft",
                      body: "Your buttocks, thighs and stomach should stay relaxed. Keep breathing normally throughout."),
                .init(heading: "Don't test on the toilet",
                      body: "Don't practice by stopping your urine flow. It can interfere with emptying your bladder properly."),
            ],
            keyPoints: [
                "Think “lift and squeeze inwards”, not “push down”.",
                "Keep buttocks, thighs and stomach relaxed.",
                "Never practice while urinating.",
            ]
        ),
        LearnLesson(
            id: "relax", category: .basics, number: 3,
            title: "How to relax and breathe",
            summary: "Relaxation is just as important as contraction.",
            systemImage: "wind", minutes: 4, art: .symbol("wind"),
            sections: [
                .init(heading: "Let go completely",
                      body: "After each contraction, release the muscles fully and feel them drop back to rest. Take as long as you need before the next one."),
                .init(heading: "Breathe throughout",
                      body: "Breathe in through your nose and out through your mouth. Many people find it easier to lift gently on the out-breath."),
                .init(heading: "Notice tension",
                      body: "If the muscles don't seem to let go, slow down, take a few calm breaths and try again with a lighter effort."),
            ],
            keyPoints: [
                "Every contraction ends with a full release.",
                "Never hold your breath.",
                "Lighter effort is better than tension.",
            ]
        ),
        LearnLesson(
            id: "mistakes", category: .basics, number: 4,
            title: "Common mistakes",
            summary: "Avoid the most common technique errors.",
            systemImage: "exclamationmark.triangle", minutes: 3, art: .symbol("exclamationmark.triangle.fill"),
            sections: [
                .init(heading: "Holding your breath",
                      body: "Holding your breath increases pressure in your abdomen. Keep breathing steadily during every phase."),
                .init(heading: "Using the wrong muscles",
                      body: "Squeezing your buttocks, thighs or stomach can feel like effort but isn't the movement you need."),
                .init(heading: "Bearing down",
                      body: "Pushing down, as if straining, is the opposite of the lift you're aiming for."),
                .init(heading: "Skipping the rest",
                      body: "Rushing from one contraction to the next without relaxing can leave the muscles tense."),
            ],
            keyPoints: [
                "Breathe, lift, release.",
                "If in doubt, use less effort.",
                "The Common Mistakes tab has more detail.",
            ]
        ),
        LearnLesson(
            id: "safety", category: .basics, number: 5,
            title: "Safety and best practices",
            summary: "Stay safe and know when to stop.",
            systemImage: "cross.case", minutes: 3, art: .symbol("cross.case.fill"),
            sections: [
                .init(heading: "Stop if it hurts",
                      body: "Stop practicing if you feel pain, pressure or discomfort, and don't continue until you've spoken with a professional."),
                .init(heading: "When to seek support",
                      body: "Talk to a doctor or pelvic health professional if you have ongoing pain, bladder or bowel problems, symptoms after surgery, or anything that worries you."),
                .init(heading: "What this app is",
                      body: "Control offers general guided practice and education. It does not diagnose, treat or monitor any condition."),
            ],
            keyPoints: [
                "Pain or discomfort means stop.",
                "A professional can check your technique.",
                "This app is not a medical service.",
            ]
        ),
    ]

    // MARK: - How to

    static let firstSession = LearnLesson(
        id: "first-session", category: .howTo,
        title: "Your first guided session",
        summary: "What happens during a Control session, step by step, and how to pause or stop at any time.",
        systemImage: "play.circle", minutes: 3, art: .rhythm,
        sections: [
            .init(heading: "Contract and relax phases",
                  body: "Each session alternates between a short contract phase and a longer relax phase. A spoken countdown and the screen tell you which phase you're in."),
            .init(heading: "Follow at your own pace",
                  body: "If a contraction feels like too much, use a lighter effort. You can pause or end the session at any time."),
            .init(heading: "After the session",
                  body: "You'll be asked how it felt. If you report pain or discomfort, new sessions are paused and you'll be encouraged to seek professional advice."),
        ],
        keyPoints: [
            "Contract gently, then relax fully.",
            "Pause or stop whenever you need to.",
            "Report discomfort honestly after each session.",
        ]
    )

    static let howTo: [LearnLesson] = [
        LearnLesson(
            id: "find", category: .howTo, number: 1,
            title: "Finding the right muscles",
            summary: "Simple cues to locate your pelvic floor.",
            systemImage: "scope", minutes: 3, art: .symbol("scope"),
            sections: [
                .init(heading: "Get comfortable",
                      body: "Lie on your back with your knees bent, or sit upright on a firm chair. Let your stomach, buttocks and legs relax."),
                .init(heading: "Use a cue",
                      body: "Imagine stopping wind, or drawing the base of your penis slightly upwards and inwards. Choose whichever cue feels clearest."),
                .init(heading: "Check yourself",
                      body: "Rest a hand on your stomach and another on your buttock. Both should stay soft while you lift."),
            ],
            keyPoints: [
                "Start lying down or sitting.",
                "Pick one cue and stick with it.",
                "Hands on stomach and buttock help you check.",
            ]
        ),
        LearnLesson(
            id: "hold", category: .howTo, number: 2,
            title: "Contract and hold",
            summary: "Lift gently and hold without straining.",
            systemImage: "timer", minutes: 3, art: .symbol("timer"),
            sections: [
                .init(heading: "Lift",
                      body: "Breathe out and gently lift the pelvic floor inwards and upwards."),
                .init(heading: "Hold briefly",
                      body: "Hold only as long as you can keep a steady, comfortable lift while breathing normally. A short, good-quality hold is better than a long, strained one."),
                .init(heading: "Follow the countdown",
                      body: "During a session the countdown tells you when to lift and when to let go. If you can't hold for the whole phase, release early and rest."),
            ],
            keyPoints: [
                "Breathe out as you lift.",
                "Quality matters more than length.",
                "Release early if you lose control of the lift.",
            ]
        ),
        LearnLesson(
            id: "release", category: .howTo, number: 3,
            title: "Letting go completely",
            summary: "Make every release count.",
            systemImage: "arrow.down.circle", minutes: 3, art: .symbol("arrow.down.circle.fill"),
            sections: [
                .init(heading: "Feel the drop",
                      body: "At the end of each contraction, let the muscles fully return to rest. You may feel a gentle sense of softening or dropping."),
                .init(heading: "Rest as long as you lift",
                      body: "The relax phase is usually longer than the contract phase. Use all of it to recover."),
                .init(heading: "Breathe into your belly",
                      body: "A slow breath into your stomach can help the pelvic floor relax."),
            ],
            keyPoints: [
                "Every lift ends with a full release.",
                "Use the whole relax phase.",
                "Slow belly breaths help you let go.",
            ]
        ),
        LearnLesson(
            id: "positions", category: .howTo, number: 4,
            title: "Choosing a position",
            summary: "Lying, sitting and standing practice.",
            systemImage: "figure.seated.side", minutes: 3, art: .symbol("figure.seated.side"),
            sections: [
                .init(heading: "Lying down",
                      body: "Often the easiest place to start, because the muscles don't have to work against gravity."),
                .init(heading: "Sitting",
                      body: "Sit upright on a firm chair with your feet flat and your weight evenly spread."),
                .init(heading: "Standing",
                      body: "Once lifting and relaxing feel familiar, you can try standing with your feet hip-width apart."),
            ],
            keyPoints: [
                "Start in the position that feels easiest.",
                "Keep good posture and relaxed shoulders.",
                "Only change position when technique feels steady.",
            ]
        ),
        LearnLesson(
            id: "routine", category: .howTo, number: 5,
            title: "Building a gentle routine",
            summary: "Consistency over intensity.",
            systemImage: "calendar", minutes: 3, art: .symbol("calendar"),
            sections: [
                .init(heading: "Short and regular",
                      body: "Short, regular practice is easier to keep up than occasional long sessions. Choose a time of day that fits your routine."),
                .init(heading: "Don't overdo it",
                      body: "More isn't always better. Tired muscles find it harder to lift and relax with good technique."),
                .init(heading: "Track what you've done",
                      body: "The Progress tab shows the sessions you've completed. It records practice only and doesn't measure muscle strength or symptoms."),
            ],
            keyPoints: [
                "Pick a regular time.",
                "Stop when technique starts to slip.",
                "Progress shows practice, not health results.",
            ]
        ),
    ]

    // MARK: - Common mistakes

    static let whyTechniqueMatters = LearnLesson(
        id: "why-technique", category: .mistakes,
        title: "Why technique matters",
        summary: "Small technique errors are common. Learn how to spot them and what to do instead.",
        systemImage: "checkmark.seal", minutes: 2, art: .symbol("checkmark.seal.fill"),
        sections: [
            .init(heading: "Common and fixable",
                  body: "Many people use the wrong muscles or hold their breath when they first try. That's normal, and it's usually easy to correct once you know what to look for."),
            .init(heading: "Slow down",
                  body: "If something feels wrong, stop, relax, take a breath and try again with less effort."),
            .init(heading: "Ask for help",
                  body: "A pelvic health professional can check your technique in person if you're unsure."),
        ],
        keyPoints: [
            "Mistakes are common at the start.",
            "Less effort often means better technique.",
            "Professional advice is available if you're unsure.",
        ]
    )

    static let mistakes: [LearnLesson] = [
        LearnLesson(
            id: "breath-holding", category: .mistakes, number: 1,
            title: "Holding your breath",
            summary: "Keep breathing through every phase.",
            systemImage: "lungs", minutes: 2, art: .symbol("lungs.fill"),
            sections: [
                .init(heading: "What happens",
                      body: "Holding your breath while you lift raises pressure inside your abdomen, which pushes down on the pelvic floor."),
                .init(heading: "Try instead",
                      body: "Breathe out as you lift and keep breathing gently while you hold. If you notice you've stopped breathing, release and start again."),
            ],
            keyPoints: ["Breathe out as you lift.", "Keep breathing while you hold."]
        ),
        LearnLesson(
            id: "wrong-muscles", category: .mistakes, number: 2,
            title: "Squeezing the wrong muscles",
            summary: "Buttocks, thighs and stomach stay soft.",
            systemImage: "hand.raised", minutes: 2, art: .symbol("hand.raised.fill"),
            sections: [
                .init(heading: "What happens",
                      body: "Clenching your buttocks, pressing your thighs together or tightening your stomach can feel like hard work, but it isn't the pelvic floor lift."),
                .init(heading: "Try instead",
                      body: "Rest a hand on your stomach and buttock. If you feel them tighten, ease off and focus on a small inward lift."),
            ],
            keyPoints: ["A correct lift is small and internal.", "Use your hands to check for extra tension."]
        ),
        LearnLesson(
            id: "bearing-down", category: .mistakes, number: 3,
            title: "Pushing down instead of lifting",
            summary: "Lift up and in, never strain.",
            systemImage: "arrow.down.to.line", minutes: 2, art: .symbol("arrow.down.to.line"),
            sections: [
                .init(heading: "What happens",
                      body: "Straining or bearing down, as you might on the toilet, moves the pelvic floor in the opposite direction."),
                .init(heading: "Try instead",
                      body: "Think of drawing upwards and inwards. If you can't tell which way you're moving, stop and speak with a professional."),
            ],
            keyPoints: ["The movement is up and in.", "Never strain or push down."]
        ),
        LearnLesson(
            id: "no-relax", category: .mistakes, number: 4,
            title: "Skipping the relaxation",
            summary: "Rest fully before the next lift.",
            systemImage: "pause.circle", minutes: 2, art: .symbol("pause.circle.fill"),
            sections: [
                .init(heading: "What happens",
                      body: "Going straight into the next contraction without letting go can leave the muscles tired and tense."),
                .init(heading: "Try instead",
                      body: "Use the whole relax phase. Feel the muscles return to rest before you lift again."),
            ],
            keyPoints: ["Every lift needs a full rest.", "Tension isn't the goal."]
        ),
        LearnLesson(
            id: "on-toilet", category: .mistakes, number: 5,
            title: "Practicing on the toilet",
            summary: "Don't stop and start your urine flow.",
            systemImage: "drop", minutes: 2, art: .symbol("drop.fill"),
            sections: [
                .init(heading: "What happens",
                      body: "Repeatedly stopping your urine flow can interfere with emptying your bladder properly."),
                .init(heading: "Try instead",
                      body: "Practice at another time, lying down or sitting, with an empty bladder."),
            ],
            keyPoints: ["Never practice while urinating.", "Empty your bladder before a session."]
        ),
        LearnLesson(
            id: "overdoing", category: .mistakes, number: 6,
            title: "Doing too much, too soon",
            summary: "More practice isn't always better.",
            systemImage: "gauge.with.dots.needle.67percent", minutes: 2, art: .symbol("gauge.with.dots.needle.67percent"),
            sections: [
                .init(heading: "What happens",
                      body: "Long or very frequent sessions can tire the muscles, making good technique harder and sometimes causing discomfort."),
                .init(heading: "Try instead",
                      body: "Stick to the guided session and stop if you feel pain or discomfort. Rest days are fine."),
            ],
            keyPoints: ["Follow the guided session.", "Stop if anything hurts."]
        ),
    ]
}
