Shader "Unlit/TriplanarMapping"
{
	Properties
	{
		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex("Texture", 2D) = "white" {}
		_TexScale("Texture Scale", Float) = 1.0
		[Toggle] _VisPlanes("Visualize Planes", Float) = 0.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

struct v2f
{
	float4 vertex  : SV_POSITION;
	float2 uv      : TEXCOORD0;
	float3 wNormal : TEXCOORD1;
	float3 wPos    : TEXCOORD2;
};

sampler2D _MainTex;
float4 _MainTex_ST;

v2f vert(appdata_base v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.wNormal = UnityObjectToWorldNormal(v.normal);
	o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
return o;
}

half4 _Color;
half _TexScale;
half _VisPlanes;

inline void SampleTriPlanar(half3 absNormal, half3 absSum, half3 wPos, sampler2D inCol, out half3 col)
{
	half3 c0 = half3(1.0, 1.0, 1.0);
	half3 c1 = half3(1.0, 1.0, 1.0);
	half3 c2 = half3(1.0, 1.0, 1.0);

	half2 dervX = ddx(wPos);
	half2 dervY = ddy(wPos);

	if (absNormal.r > 0.0)
	{
		c0 = tex2D(inCol, wPos.zy, dervX, dervY);
	}
	if (absNormal.g > 0.0)
	{
		c1 = tex2D(inCol, wPos.xz, dervX, dervY);
	}
	if (absNormal.b > 0.0)
	{
		c2 = tex2D(inCol, wPos.xy, dervX, dervY);
	}

	if (_VisPlanes)
	{
		c0 = half3(1.0, 0.0, 0.0);
		c1 = half3(0.0, 1.0, 0.0);
		c2 = half3(0.0, 0.0, 1.0);
	}

	col = (c0 * absSum.r) + (c1 * absSum.g) + (c2 * absSum.b);
}

fixed4 frag(v2f i) : SV_Target
{
	const half _tighten = 0.576;

	half3 absNormal = abs(normalize(i.wNormal)) - _tighten;
	absNormal = max(0.0, absNormal);

	half sum = dot(absNormal, half3(1.0, 1.0, 1.0));
	sum = max(sum, 1.0 / 255.0);
	half3 absSum = absNormal / sum;

	half3 col;
	SampleTriPlanar(absNormal, absSum, i.wPos * _TexScale, _MainTex, col);

	half3 wLightlDir = UnityWorldSpaceLightDir(i.wPos);
	half halfLambet = -dot(wLightlDir.xyz, i.wNormal) * 0.5 + 0.5;

return half4(col, 1.0) * _Color * halfLambet;
}
ENDCG
		}
	}
}
