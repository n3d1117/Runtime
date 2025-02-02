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
                        .safeAreaInset(edge: .top, spacing: .zero) {
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
            .toolbarBackground(.hidden, for: .navigationBar)
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
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    
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
                            Text("Filters") + (viewModel.filterOptions.isEmpty ? Text("") : (
                                Text(" ") + Text(Image(systemName: "\(viewModel.filterOptions.count).circle.fill"))
                            ))
                            
                            Image(systemName: "chevron.down")
                                .imageScale(.small)
                                .offset(y: 1)
                        }
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Button("Reload") {
                        Task {
                            viewModel.clearCache()
                            await viewModel.fetchWorkouts()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 3)
                .padding(.bottom, 10)
                .foregroundStyle(.primary)
                .tint(.secondary)
                .buttonStyle(.bordered)
            }
            .scrollIndicators(.hidden)
            .background(.regularMaterial)
            
            Divider()
                .overlay(Color(UIColor.opaqueSeparator))
        }
    }
}
