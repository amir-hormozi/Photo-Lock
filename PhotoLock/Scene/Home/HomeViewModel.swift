//
//  HomeViewModel.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    
    enum Tab {
        case encrypt
        case decrypt
        case keys
    }
    
    @Published private(set) var selectedTab: Tab = .encrypt
    
    func didSelectTab(at index: Int) {
        switch index {
        case 0:
            selectedTab = .encrypt
        case 1:
            selectedTab = .decrypt
        case 2:
            selectedTab = .keys
        default:
            break
        }
    }
}
