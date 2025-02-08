//
//  ContentView.swift
//  TideTimes
//
//  Created by Tarang Srivastava on 2/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TideViewModel()
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            ScrollView {  // Make the view scrollable
                VStack(spacing: 16) {
                    if let location = viewModel.selectedLocation {
                        LocationHeader(location: location)
                        if let tideData = viewModel.tideData {
                            TideGraph(tideData: tideData)
                                .frame(height: 200)
                                .padding()
                            
                            TideExtremesTable(tideData: tideData)
                        } else if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else if viewModel.error != nil {
                            Text("Error loading tide data")
                                .foregroundColor(.red)
                        }
                    } else {
                        LocationSearchPrompt()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.backgroundPrimary))
            .navigationTitle("Tide Times")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isSearching = true
                    } label: {
                        Image(systemName: viewModel.selectedLocation == nil ? "magnifyingglass" : "location.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $isSearching) {
                LocationSearchView(
                    searchResults: [],
                    selectedLocation: $viewModel.selectedLocation
                )
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
