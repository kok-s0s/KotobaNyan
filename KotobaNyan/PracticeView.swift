import SwiftUI

struct PracticeView: View {
    @ObservedObject var viewModel: VocabularyViewModel

    var masteredCount: Int { viewModel.items.filter { $0.isMastered }.count }
    var reviewingCount: Int { viewModel.items.filter { $0.reviewCount > 0 }.count }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("练习模式")) {
                    NavigationLink(destination: ReviewView(viewModel: viewModel)) {
                        PracticeModeRow(
                            icon: "arrow.clockwise.circle.fill",
                            iconColor: .blue,
                            title: "间隔复习",
                            subtitle: "今日待复习：\(viewModel.dueItems.count) 词"
                        )
                    }
                    NavigationLink(destination: QuizView(viewModel: viewModel)) {
                        PracticeModeRow(
                            icon: "checkmark.square.fill",
                            iconColor: .green,
                            title: "测验模式",
                            subtitle: "日→中 / 中→日 选择题"
                        )
                    }
                    NavigationLink(destination: DictationView(viewModel: viewModel)) {
                        PracticeModeRow(
                            icon: "ear.fill",
                            iconColor: .orange,
                            title: "听写模式",
                            subtitle: "只听语音，猜词汇"
                        )
                    }
                }

                Section(header: Text("学习统计")) {
                    StatRow(icon: "text.badge.checkmark", color: .purple,
                            title: "总词汇", value: "\(viewModel.items.count) 个")
                    StatRow(icon: "checkmark.circle.fill", color: .green,
                            title: "已掌握", value: "\(masteredCount) 个")
                    StatRow(icon: "heart.fill", color: .red,
                            title: "已收藏", value: "\(viewModel.favoriteItems.count) 个")
                    StatRow(icon: "arrow.clockwise", color: .blue,
                            title: "复习中", value: "\(reviewingCount) 个")
                }
            }
            .navigationTitle("练习")
        }
    }
}

struct PracticeModeRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title2)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}
