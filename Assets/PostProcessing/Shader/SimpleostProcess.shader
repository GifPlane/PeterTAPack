Shader "Hidden/JiaMi/ImageEffect/SimplePostProcess"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "" {}
    }

    CGINCLUDE
    #include "UnityCG.cginc"
    #define lum fixed3(0.212673h, 0.715152h, 0.072175h)
    #define hal fixed3(0.5h, 0.5h, 0.5h)

    struct appdata
    {
        fixed4 pos : POSITION;
        fixed2 uv : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2fb
    {
        fixed4 pos : SV_POSITION;
        fixed4 uv : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    struct v2f
    {
        fixed4 pos : SV_POSITION;
        fixed4 uv : TEXCOORD0;
        fixed4 uv1 : TEXCOORD1;
        fixed4 uv2 : TEXCOORD2;
        fixed2 uv3 : TEXCOORD3;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    uniform UNITY_DECLARE_TEX3D(_LutTex);
    uniform UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
    uniform UNITY_DECLARE_SCREENSPACE_TEXTURE(_MaskTex);
    uniform UNITY_DECLARE_SCREENSPACE_TEXTURE(_BlurTex);
    uniform fixed _LutAmount;
    uniform fixed4 _BloomColor;
    uniform fixed _BloomIntensity;
    uniform fixed _BlurAmount;
    uniform fixed _BloomDiffuse;
    uniform fixed4 _Color;
    uniform fixed4 _BloomData;
    uniform fixed _Contrast;
    uniform fixed _Brightness;
    uniform fixed _Saturation;
    uniform fixed _CentralFactor;
    uniform fixed _SideFactor;
    uniform fixed _Offset;
    uniform fixed _FishEye;
    uniform fixed4 _VignetteColor;
    uniform fixed _VignetteAmount;
    uniform fixed _VignetteSoftness;
    uniform fixed4 _MainTex_TexelSize;

    v2fb vertBlur(appdata i)
    {
        v2fb o;
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_INITIALIZE_OUTPUT(v2fb, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        o.pos = UnityObjectToClipPos(i.pos);
        #if defined(BLOOM)
			fixed2 offset = _MainTex_TexelSize.xy * _BloomDiffuse;
        #else
        fixed2 offset = _MainTex_TexelSize.xy * _BlurAmount;
        #endif
        o.uv = fixed4(i.uv - offset, i.uv + offset);
        return o;
    }

    v2f vert(appdata i)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_INITIALIZE_OUTPUT(v2f, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        o.pos = UnityObjectToClipPos(i.pos);
        o.uv.xy = UnityStereoTransformScreenSpaceTex(i.uv);
        o.uv.zw = i.uv;
        o.uv1 = fixed4(o.uv.xy - _MainTex_TexelSize.xy, o.uv.xy + _MainTex_TexelSize.xy);
        o.uv2.x = o.uv.x - _Offset * _MainTex_TexelSize.x - 0.5h;
        o.uv2.y = o.uv.x + _Offset * _MainTex_TexelSize.x - 0.5h;
        o.uv2.zw = i.uv - 0.5h;
        o.uv3 = o.uv.xy - 0.5h;
        return o;
    }

    fixed4 fragBlur(v2fb i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        fixed4 b = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, i.uv.xy);
        b += UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, i.uv.xw);
        b += UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, i.uv.zy);
        b += UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, i.uv.zw);
        return b * 0.25h;
    }

    fixed4 frag(v2f i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

        fixed q = dot(i.uv2.zw, i.uv2.zw);
        fixed q2 = sqrt(q);

        fixed4 c = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, i.uv.xy);

        #if defined(BLOOM)
			fixed4 b = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_BlurTex, i.uv.xy);
        #endif

        #if !defined(UNITY_NO_LINEAR_COLORSPACE)
        c.rgb = sqrt(c.rgb);
        #if defined(BLOOM)|| defined(BLUR)
				b.rgb = sqrt(b.rgb);
        #endif
        #endif

        #ifdef LUT
        c = lerp(c, UNITY_SAMPLE_TEX3D(_LutTex, c.rgb * 0.9375h + 0.03125h), _LutAmount);
        #if defined(BLOOM)
				b = lerp(b, UNITY_SAMPLE_TEX3D(_LutTex, b.rgb * 0.9375h + 0.03125h), _LutAmount);
        #endif
        #endif

        #ifdef BLOOM
        	// fixed br = max(b.r, max(b.g, b.b));
        	// fixed soft = clamp(br - _BloomData.y, 0.0h, _BloomData.z);
        	// b *= max(soft * soft * _BloomData.w, br - _BloomData.x) * _BloomColor;
        	// #if !defined(UNITY_NO_LINEAR_COLORSPACE)
        	//  	b.rgb *= b.rgb;
        	//  #endif
        	c += (b * _BloomIntensity * _BloomColor);

        #endif

        #ifdef FILTER
        c.rgb = _Contrast * c.rgb + _Brightness;
        c.rgb = lerp(dot(c.rgb, lum), c.rgb, _Saturation) * _Color.rgb;
        #endif
        c.rgb = lerp(_VignetteColor.rgb, c.rgb, smoothstep(_VignetteAmount, _VignetteSoftness, q2));

        #if !defined(UNITY_NO_LINEAR_COLORSPACE)
        c.rgb *= c.rgb;
        #endif
        return c;
    }

    ENDCG

    Subshader
    {
        ZTest Always Cull Off ZWrite Off
        Fog
        {
            Mode off
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature LUT
            #pragma shader_feature BLOOM
            #pragma shader_feature FILTER
            #pragma fragmentoption ARB_precision_hint_fastest
            ENDCG
        }
    }
    Fallback off
}