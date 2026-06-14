import SwiftUI
import StoreKit

/// Focus Quest Pro paywall. Lists the subscription options from StoreKit, shows
/// the benefits, and handles purchase + restore. Presented as a sheet.
struct PaywallView: View {
    @EnvironmentObject var store: PurchaseStore
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var working = false

    private var benefits: [String] { ["pro.benefit.1", "pro.benefit.2", "pro.benefit.3"] }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 18) {
                    benefitList
                    if store.isPro {
                        Text(loc("pro.current"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.gold)
                            .padding(.top, 8)
                    } else if store.products.isEmpty {
                        Text(loc("pro.noProducts"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    } else {
                        ForEach(store.products, id: \.id) { product in
                            planButton(product)
                        }
                    }
                }
                .padding(24)
            }
            footer
        }
        .frame(width: 380, height: 540)
        .background(Theme.bg)
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Theme.goldGradient).frame(width: 72, height: 72)
                Image(systemName: "crown.fill").font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
            }
            .padding(.top, 28)
            Text(loc("pro.title"))
                .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Text(loc("pro.tagline"))
                .font(.system(size: 14, design: .rounded)).foregroundStyle(Theme.textSecondary)
        }
    }

    private var benefitList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(benefits, id: \.self) { key in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18)).foregroundStyle(Theme.gold)
                    Text(loc(key)).font(.system(size: 14, design: .rounded)).foregroundStyle(.white)
                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func planButton(_ product: Product) -> some View {
        Button {
            Task { working = true; let ok = await store.purchase(product); working = false; if ok { dismiss() } }
        } label: {
            HStack {
                Text(product.displayName.isEmpty ? product.id : product.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Spacer()
                Text(product.displayPrice)
                    .font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(working)
    }

    private var footer: some View {
        HStack {
            Button(loc("pro.restore")) { Task { await store.restore(); if store.isPro { dismiss() } } }
                .buttonStyle(.plain).font(.system(size: 12, design: .rounded)).foregroundStyle(Theme.textSecondary)
            Spacer()
            Button(loc("pro.maybeLater")) { dismiss() }
                .buttonStyle(.plain).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Theme.primaryHi)
        }
        .padding(.horizontal, 24).padding(.vertical, 16)
        .background(Theme.surface)
    }
}
