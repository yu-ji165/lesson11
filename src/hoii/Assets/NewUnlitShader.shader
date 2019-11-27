﻿Shader "Unlit/NewUnlitShader"
{
    Properties
    {
			 _AlbedoTex("Texture", 2D) = "white" {}
			 _HeightTex("Texture", 2D) = "white" {}
			 _HeightScale("Height Scale", Range(0,10.)) = 1.0
			 _TessFactor("Tess Factor", Range(1,10.0)) = 10
	}
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
			#pragma vertex vert
			#pragma hull hull
			#pragma domain dom
			#pragma fragment frag
			// make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
				float4 pos:POSITION;
                float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
            };
	
            struct v2h
			{
				float4 pos:POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
			};

			struct h2d_main
			{
				float4 pos:POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
			};

			struct h2d_const
			{
				float tess_factor[3]:SV_TessFactor;
				float InsideTessFactor : SV_InsideTessFactor;
			};

			struct d2f
			{
				float4 pos:SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _AlbedoTex;
			sampler2D _HeightTex;
			float4 _AlbedoTex_ST;
			float _HeightScale;
			float _TessFactor;

            v2h vert (appdata v)
            {
				v2h o = (v2h)0;
				o.pos = v.pos;
				o.uv = v.uv;
				o.normal = v.normal;
                return o;
            }

			h2d_const HSConst(InputPatch<v2h, 3> i)
			{
				h2d_const o = (h2d_const)0;
				o.tess_factor[0] = _TessFactor;
				o.tess_factor[1] = _TessFactor;
				o.tess_factor[2] = _TessFactor;
				o.InsideTessFactor = _TessFactor;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[outputcontrolpoints(3)]
			[patchconstantfunc("HSConst")]
			h2d_main hull(InputPatch<v2h, 3> i, uint id:SV_OutputControlPointID)
			{
				h2d_main o = (h2d_main)0;
				o.pos = i[id].pos;
				o.uv = i[id].uv;
				o.normal = i[id].normal;
				return o;
			}

			[domain("tri")]
			d2f dom(h2d_const hs_const_data, const OutputPatch<h2d_main, 3> i, float3 bary:SV_DomainLocation)
			{
				d2f o = (d2f)0;
				o.uv = i[0].uv * bary.x + i[1].uv * bary.y + i[2].uv * bary.z;
				float3 nrm = i[0].normal * bary.x + i[1].normal * bary.y + i[2].normal * bary.z;
				float3 pos = i[0].pos * bary.x + i[1].pos * bary.y + i[2].pos * bary.z;

				fixed height = tex2Dlod(_HeightTex, float4(o.uv, 0, 0)).x;
				pos += nrm * height*_HeightScale;

				o.pos = UnityObjectToClipPos(float4(pos, 1));
				return o;
			}

            fixed4 frag (d2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_AlbedoTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}