//
// Sejun Ahn
// github: github.com/sejun-ahn
//

import Foundation
import SwiftUI

extension View {
    func smallStyle() -> some View {
        return self
            .frame(width: 80, height: 30, alignment: .center)
            .cornerRadius(6)
    }
    
    func smallStyleVal() -> some View {
        return self
            .frame(width: 80, height: 30, alignment: .center)
            .background(.white)
            .cornerRadius(6)
    }
    
    func mediumStyle() -> some View {
        return self
            .frame(width: 165, height: 30, alignment: .center)
            .cornerRadius(6)
    }
    
    func largeStyle() -> some View {
        return self
            .frame(width: 250, height: 30, alignment: .center)
            .cornerRadius(6)
    }
    
    func toggleButtonStyle(flag: Bool) -> some View {
        return self
            .background(flag ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    func buttonStyle(flag: Bool) -> some View {
        return self
            .background(flag ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(6)
            .disabled(!flag)
    }
    
    func textFieldStyle(flag: Bool) -> some View {
        return self
            .background(Color.white)
            .cornerRadius(6)
            .multilineTextAlignment(.center)
            .disabled(flag)
    }
}
