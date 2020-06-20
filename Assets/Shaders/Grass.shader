﻿Shader "Custom/Grass"
{
	Properties
	{
		_GrassHeight("Grass height", float) = 0
        _GrassOffset("Grass Blades Offset", Range(0, 0.1)) = 0.05

		_ShakeStrength("Shake Strength", Range(0, 0.1)) = 0.01
        _ShakeFrequency("Shake Frequency", Range(0, 100)) = 10

		_GrassBlades("Grass blades per triangle", Range(0, 15)) = 1
		_MinimunGrassBlades("Minimum grass blades per triangle", Range(0, 15)) = 1
		_MaxCameraDistance("Max camera distance", float) = 10
	}
		SubShader
	{
		CGINCLUDE

			#include "UnityCG.cginc"

			float _GrassHeight;
            float _GrassOffset;

			float _ShakeStrength;
            float _ShakeFrequency;
			
			float _GrassBlades;
			float _MinimunGrassBlades;
			float _MaxCameraDistance;

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2g
			{
				float4 vertex : POSITION;
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 col : COLOR;
			};

			float random2(float2 st)
			{
				return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
			}

			float perlinNoise(float2 uv)
			{
				float2 ipos = floor(uv);
				float2 fpos = frac(uv);

				float2 lb = ipos + float2(0.0, 0.0);
				float2 rb = ipos + float2(1.0, 0.0);
				float2 lt = ipos + float2(0.0, 1.0);
				float2 rt = ipos + float2(1.0, 1.0);

				// smoothstep
				//vec2 u = fpos * fpos * (3.0 - 2.0 * fpos);

				// quintic interpolation curve
				float2 u = fpos * fpos * fpos * (fpos * (fpos * 6. - 15.) + 10.);

				return lerp(
							lerp(dot(random2(lb), fpos - float2(0., 0.)),
								 dot(random2(rb), fpos - float2(1., 0.)), u.x),
							lerp(dot(random2(lt), fpos - float2(0., 1.)),
								 dot(random2(rt), fpos - float2(1., 1.)), u.x), u.y);
			}

			g2f GetVertex(float4 pos, float2 uv, fixed4 col)
			{
				g2f o;
				o.vertex = UnityObjectToClipPos(pos);
				o.uv = uv;
				o.col = col;
				return o;
			}

			v2g vert(appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				return o;
			}

			[maxvertexcount(48)]
			void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
			{
				float3 normal = normalize(cross(input[1].vertex - input[0].vertex, input[2].vertex - input[0].vertex));
				int grassBlades = ceil(lerp(_GrassBlades, _MinimunGrassBlades, saturate(distance(_WorldSpaceCameraPos, mul(unity_ObjectToWorld, input[0].vertex)) / _MaxCameraDistance)));
				
				for (int i = 0; i < grassBlades; i++)
				{
					float r1 = random2(mul(unity_ObjectToWorld, input[0].vertex).xz * (i + 1));
					float r2 = random2(mul(unity_ObjectToWorld, input[1].vertex).xz * (i + 1));

					float4 midpoint = (1 - sqrt(r1)) * input[0].vertex + (sqrt(r1) * (1 - r2)) * input[1].vertex + (sqrt(r1) * r2) * input[2].vertex;
					float4 pointA = midpoint + 0.005 * normalize(input[i % 3].vertex - midpoint);
					float4 pointB = midpoint - 0.005 * normalize(input[i % 3].vertex - midpoint);

					r1 = r1 * 2.0 - 1.0;
					r2 = r2 * 2.0 - 1.0;

					float3 worldPos = mul(unity_ObjectToWorld, pointA);

					float noise = perlinNoise(worldPos.xz) * 0.5 + 0.5;
					float heightFactor = noise * _GrassHeight;

					float offset = sin((worldPos.x + worldPos.z) * (r1+ r2) * 5 + _Time.y * _ShakeFrequency) * noise;
			
					float4 newVertexPoint = midpoint + float4(normal, 0.0) * heightFactor;
                    newVertexPoint += + float4(r1, 0, r2, 0) * _GrassOffset;    // offset
                    newVertexPoint += float4(offset, 0, offset, 0) * _ShakeStrength * heightFactor;

					triStream.Append(GetVertex(pointA, float2(0, 0), fixed4(0, 0, 0, 1)));
					triStream.Append(GetVertex(newVertexPoint, float2(0.5, 1), fixed4(1.0, 1.0, 1.0, 1.0)));
					triStream.Append(GetVertex(pointB, float2(1, 0), fixed4(0, 0, 0, 1)));

					triStream.RestartStrip();
				}

				for (int i = 0; i < 3; i++)
				{
					triStream.Append(GetVertex(input[i].vertex, float2(0, 0), fixed4(0, 0, 0, 1)));
				}

				triStream.RestartStrip();
			}

			fixed4 frag(g2f i) : SV_Target
			{
				
				
				return fixed4(0, i.uv.y, 0, 0);
			}

		ENDCG

        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Cull Off

            CGPROGRAM
            #pragma vertex vert
			#pragma geometry geom
            #pragma fragment frag

            #pragma target 4.0


            ENDCG
        }
    }
}
