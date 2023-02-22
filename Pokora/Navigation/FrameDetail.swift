//
//  FrameDetail.swift
//  Pokora
//
//  Created by PJ Gray on 2/22/23.
//

import SwiftUI

struct FrameDetail: View {
    @EnvironmentObject var store: Store
    @Binding var frameId: Frame.ID?

    var body: some View {
        Text("Frame #\(frame.id)")
    }
}

struct FrameDetail_Previews: PreviewProvider {
    static var store = Store()
    static var previews: some View {
        FrameDetail(frameId:
            .constant(store.frames.first!.id))
            .environmentObject(store)
    }
}

extension FrameDetail {
    
    var frame: Frame {
        store[frameId]
    }
    
    var frameBinding: Binding<Frame> {
        $store[frameId]
    }

}
