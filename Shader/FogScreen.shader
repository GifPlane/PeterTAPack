Shader "JiaMi/Env/FogScreen"
{
    Properties
    {
        [HideInInspector]_CameraSpeedMultiplier("Camera Speed Multiplier", float) = 1.0
        [HideInInspector]_UVChangeX("UV Change X", float) = 1.0
        [HideInInspector]_UVChangeY("UV Change Y", float) = 1.0
        [HideInInspector]_Size("Size", float) = 2.0
        [HideInInspector]_Speed("Horizontal Speed", float) = 0.2
        [HideInInspector]_VSpeed("Vertical Speed", float) = 0
        [HideInInspector]_Density("Density", float) = 1
        [HideInInspector]_MainTex("Base (RGB)", 2D) = "white" {}
        [HideInInspector]_Color("Color", Color) = (1, 1, 1, 1)
        [HideInInspector]_DarkMode("Dark Mode", float) = 0
        [HideInInspector]_DarkMultiplier("Dark Multiplier", float) = 1
        [HideInInspector]_NoiseTex("Noise", 2D) = "white" {}
    }

    Subshader
    {
        Pass
        {
            Tags
            {
                "Queue" = "Opaque"
            }
            Cull Off ZWrite Off ZTest Always
            CGPROGRAM
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            float _Size;
            float _CameraSpeedMultiplier;
            float _UVChangeX;
            float _UVChangeY;
            float _Speed;
            float _VSpeed;
            float _Density;
            float4 _Color;
            float _DarkMode;
            float _DarkMultiplier;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct vertexOutput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            float texNoise(float2 uv)
            {
                return tex2D(_NoiseTex, uv.xy).r;
            }
            
            half fog(in float2 uv)
            {
                half direction = _Time.y * _Speed;
                half Vdirection = _Time.y * _VSpeed;
                half color = 0.0;
                half total = 0.0;
                half k = 0.0;
                color += texNoise(
                    half2(
                        (uv.x * _Size + direction * 0.2),
                        (uv.y * _Size + Vdirection * 0.2)
                    )
                );
                total += 1.0;

                k = 2;
                color += texNoise(
                    half2(
                        (uv.x * _Size + direction * 0.4) * k,
                        (uv.y * _Size + Vdirection * 0.4) * k
                    )
                ) * 0.5;
                total += 0.5;

                k = 4;
                color += texNoise(
                    half2(
                        (uv.x * _Size + direction * 0.6) * k,
                        (uv.y * _Size + Vdirection * 0.6) * k
                    )
                ) * 0.25;
                total += 0.25;

                k = 8;
                color += texNoise(
                    half2(
                        (uv.x * _Size + direction * 0.8) * k,
                        (uv.y * _Size + Vdirection * 0.8) * k
                    )
                ) * 0.125;
                total += 0.125;

                color /= total;

                return clamp(color, 0.0, 1.0);
            }
            
            vertexOutput vert(appdata v)
            {
                vertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(vertexOutput i) : SV_Target
            {
                half2 fogUV = float2(i.uv.x + _UVChangeX * _CameraSpeedMultiplier,
                                     i.uv.y + _UVChangeY * _CameraSpeedMultiplier);
                half f = fog(fogUV);
                half m = min(f * _Density, 1.);
                half4 tex = tex2D(_MainTex, i.uv);
                return tex * (1 - m) + m * _Color;
            }
            ENDCG
        }
    }
}