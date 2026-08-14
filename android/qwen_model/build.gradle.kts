plugins {
    id("com.android.asset-pack")
}

assetPack {
    packName.set("qwen_model")
    dynamicDelivery {
        deliveryType.set("install-time")
    }
}
