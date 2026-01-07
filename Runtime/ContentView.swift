//
//  ContentView.swift
//  Runtime
//
//  Created by ned on 01/02/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if !viewModel.filteredWorkouts.isEmpty {
                    RunWorkoutsView(workouts: viewModel.filteredWorkouts, sortOption: viewModel.sortOption)
                        .refreshable {
                            await viewModel.fetchWorkouts()
                        }
                        .safeAreaBar(edge: .top, spacing: .zero) {
                            filtersView
                        }
                } else {
                    ProgressView("Loading...")
                }
            }
            .task { await viewModel.fetchWorkouts() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Label("Runs", systemImage: "figure.run")
                        .labelStyle(.titleAndIcon)
                        .font(.headline)
                }
            }
            .animation(.default, value: viewModel.filteredWorkouts)
        }
    }
    
    @ViewBuilder var filtersView: some View {
        VStack(spacing: .zero) {
            ScrollView(.horizontal) {
                HStack {
                    Menu {
                        Picker("", selection: $viewModel.sortOption) {
                            ForEach(ContentViewModel.SortOption.allCases, id: \.self) { option in
                                Label(option.title, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(viewModel.sortOption.title)
                            Image(systemName: "chevron.down")
                                .imageScale(.small)
                                .offset(y: 1)
                        }
                        .lineLimit(1)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    
                    Menu {
                        ForEach(ContentViewModel.FiterOption.allCases, id: \.self) { option in
                            Button {
                                viewModel.applyFilterOption(option)
                            } label: {
                                if viewModel.filterOptions.contains(option) {
                                    Label(option.title, systemImage: "checkmark")
                                } else {
                                    Text(option.title)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            HStack(spacing: 0) {
                                Text("Filters")
                                if !viewModel.filterOptions.isEmpty {
                                    Text(" ")
                                    Image(systemName: "\(viewModel.filterOptions.count).circle.fill")
                                }
                            }
                            
                            Image(systemName: "chevron.down")
                                .imageScale(.small)
                                .offset(y: 1)
                        }
                        .lineLimit(1)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    
                    Button("Reload") {
                        Task {
                            viewModel.clearCache()
                            await viewModel.fetchWorkouts()
                        }
                    }
                    .buttonStyle(.glass)
                }
                .padding(.horizontal)
                .padding(.top, 3)
                .padding(.bottom, 5)
                .foregroundStyle(.primary)
            }
            .scrollIndicators(.hidden)
        }
    }
}
