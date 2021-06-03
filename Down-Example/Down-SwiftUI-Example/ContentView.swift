//
//  ContentView.swift
//  Down-SwiftUI-Example
//
//  Created by Mikhail Ivanov on 01.06.2021.
//  Copyright © 2021 Down. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State var markdownString: String
    
    init() {
        if let readMeURL = Bundle.main.url(forResource: nil, withExtension: "md"),
           let readMeContents = try? String(contentsOf: readMeURL) {
            markdownString = readMeContents
        }
        else {
            markdownString = ""
                debugPrint("Could not load readme contents.")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack() {
                Spacer()
                Text("Hello")
                    .font(.title)
                    .padding(.top, 20.0)
                    .padding(.bottom, 2.0)
                
                Text("This example allows you to get acquainted with the work of Down inside the SwiftUI lifecycle")
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10.0)
                
                Spacer()
                
                Text("Two options for work are presented:")
                
                NavigationLink(
                    destination: DownHTML(markdownString: markdownString),
                    label: {
                        Text("1. Down HTML")
                    }).padding(.top, 5.0)
                
                NavigationLink(
                    destination: DownAttributedString(text: markdownString),
                    label: {
                        Text("2. Down Attributed String - default Styler class is used")
                    }).padding(.top, 5.0)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        
    }
}
