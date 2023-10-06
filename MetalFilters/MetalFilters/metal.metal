//
//  metal.metal
//  MetalFilters
//
//  Created by Saheem Hussain on 15/09/23.
//

#include <metal_stdlib>
using namespace metal;

#include <CoreImage/CoreImage.h>

float3 multiplyColors(float3, float3);
float3 multiplyColors(float3 mainColor, float3 colorMultiplier) { // (2)
    float3 color = float3(0,0,0);
    color.r = mainColor.r * colorMultiplier.r;
    color.g = mainColor.g * colorMultiplier.g;
    color.b = mainColor.b * colorMultiplier.b;
    return color;
};

// Simple pseudo-random number generator
float random(float2 st) {
    return fract(sin(dot(st, float2(12.9898, 78.233))) * 43758.5453);
}

float4 lerp(float4 a, float4 b, float t) {
    return (1.0 - t) * a + t * b;
}

float4 noiseFunction(float2 texCoord) {
    // Generate random noise based on texCoord
    // You can use a Perlin noise function or any other noise generation technique.
    // Ensure it returns a float4 with values between 0 and 1.
    // Example:
    return float4(random(texCoord), random(texCoord * 2.0), random(texCoord * 3.0), 1.0);
};


float4 distortColor(float4 inputColor) {
    // Apply color distortion to inputColor
    // Example:
    return inputColor + float4(0.1, -0.05, 0.0, 0.0); // Adjust values as needed
};

float calculateVignette(float2 texCoord) {
    // Calculate vignette effect based on texCoord
    // Example:
    float2 center = float2(0.5, 0.5);
    float radius = length(texCoord - center);
    return 1.0 - smoothstep(0.2, 0.2, radius); // Adjust values as needed
}

float4 adjustContrastSaturation(float4 distortedColor) {
    // Adjust contrast and saturation of distortedColor
    // Example:
    float3 gray = dot(distortedColor.rgb, float3(0.299, 0.587, 0.114));
    return lerp(distortedColor, float4(gray, distortedColor.a), 0.555); // Adjust as needed
}

float4 applyScratchesAndDust(float2 texCoord, float time) {
    // Add film scratches and dust particles over time
    
    // Calculate the position of the current pixel within the scratches and dust animation
    float animationSpeed = 1.0;  // Adjust the speed as needed
    float animationOffset = time * animationSpeed;
    
    // Calculate the position with respect to the animation
    float2 animatedTexCoord = texCoord + float2(animationOffset, 0.0);
    
    // Sample a noise texture or use procedural noise to create the effect
    float scratchIntensity = noiseFunction(animatedTexCoord).r * 0.2;
    float3 scratchColor = float3(0.8, 0.8, 0.8);  // Adjust the color
    
    // Create a transparent scratches and dust layer
    float4 scratches = float4(scratchColor * scratchIntensity, 0.0);
    
    return scratches;
}

// Define constants
constant float grainIntensity = 0.1;

extern "C" {
    namespace coreimage {
        
        float4 dyeInThree(sampler src, float3 redVector, float3 greenVector, float3 blueVector) {
            
            float2 pos = src.coord();
            float4 pixelColor = src.sample(pos);     // (4)
            
            float3 pixelRGB = pixelColor.rgb;
            
            float3 color = float3(0,0,0);
            if (pos.x
                < 0.33) {                      // (5)
                color = multiplyColors(pixelRGB, redVector);
            } else if (pos.x >= 0.33 && pos.x < 0.66) {
                color = multiplyColors(pixelRGB, greenVector);
            } else {
                color = multiplyColors(pixelRGB, blueVector);
            }
            
            return float4(color, 1.0);
        }
        
        float4 super8Filter(sampler src) {
            
            float2 pos = src.coord();
            float4 pixelColor = src.sample(pos);     // (4)
            
            float4 pixelRGB = float4(pixelColor.rgb, 1.0);
            
            // Apply film grain by adding noise
            float4 grain = noiseFunction(pos) * grainIntensity;
            pixelRGB += grain;
            
            // Apply color distortion
            float4 distortedColor = distortColor(pixelRGB);
            
            // Add vignetting
            //            float vignette = calculateVignette(pos);
            //            distortedColor *= vignette;
            
            // Apply contrast and saturation adjustments
            distortedColor = adjustContrastSaturation(distortedColor);
            
            // Add film scratches and dust particles
            //            distortedColor += applyScratchesAndDust(pos, 0.2);
            
            return distortedColor;
        }
    }
}

