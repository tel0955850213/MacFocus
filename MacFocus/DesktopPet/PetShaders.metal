#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// 胸前晃動:在指定高度(chestY)附近一個高斯帶狀區域內,做水平正弦位移,
// 模擬走路落地 / 跳躍著地時的二次彈動(secondary motion / jiggle)。
// distortionEffect 的 shader:傳入「輸出像素位置」,回傳「要取樣的原圖位置」。
[[ stitchable ]]
float2 chestJiggle(float2 position, float amp, float chestY, float band, float phase) {
    float d = (position.y - chestY) / band;
    float falloff = exp(-d * d);                 // 只在胸口高度附近作用,往上下衰減
    float wobble = sin(position.y * 0.12 + phase) * amp * falloff;
    return float2(position.x - wobble, position.y);
}
