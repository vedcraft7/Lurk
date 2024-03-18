// Made with Amplify Shader Editor v1.9.3.2
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Amp_Decal"
{
	Properties
    {
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		_BaseColor("Base Color", 2D) = "white" {}
		_AntiAlias("Anti Alias", Float) = 0
		_AntiAliasPower("Anti Alias Power", Float) = -0.32
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		[HideInInspector] _DrawOrder("_DrawOrder", Int) = 0
		[HideInInspector][Enum(Depth Bias, 0, View Bias, 1)] _DecalMeshBiasType("_DecalMeshBiasType", Int) = 0
		[HideInInspector] _DecalMeshDepthBias("_DecalMeshDepthBias", Float) = 0.0
		[HideInInspector] _DecalMeshViewBias("_DecalMeshViewBias", Float) = 0.0
		[HideInInspector] _DecalStencilWriteMask("_DecalStencilWriteMask", Int) = 16
		[HideInInspector] _DecalStencilRef("_DecalStencilRef", Int) = 16
		[HideInInspector][ToggleUI] _AffectAlbedo("Boolean", Float) = 1
		[HideInInspector][ToggleUI] _AffectNormal("Boolean", Float) = 1
        [HideInInspector][ToggleUI] _AffectAO("Boolean", Float) = 1
        [HideInInspector][ToggleUI] _AffectMetal("Boolean", Float) = 1
        [HideInInspector][ToggleUI] _AffectSmoothness("Boolean", Float) = 1
        [HideInInspector][ToggleUI] _AffectEmission("Boolean", Float) = 1
		[HideInInspector] _DecalColorMask0("_DecalColorMask0", Int) = 0
		[HideInInspector] _DecalColorMask1("_DecalColorMask1", Int) = 0
		[HideInInspector] _DecalColorMask2("_DecalColorMask2", Int) = 0
		[HideInInspector] _DecalColorMask3("_DecalColorMask3", Int) = 0

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector] _DecalBlend("_DecalBlend", Range(0.0, 1.0)) = 0.5
		[HideInInspector] _NormalBlendSrc("_NormalBlendSrc", Float) = 0.0
		[HideInInspector] _MaskBlendSrc("_MaskBlendSrc", Float) = 1.0
		[HideInInspector] _DecalMaskMapBlueScale("_DecalMaskMapBlueScale", Range(0.0, 1.0)) = 1.0

		//[HideInInspector]_Unity_Identify_HDRP_Decal("_Unity_Identify_HDRP_Decal", Float) = 1.0
	}

    SubShader
    {
		LOD 0

		
        Tags { "RenderPipeline"="HDRenderPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

		HLSLINCLUDE
		#pragma target 4.5
		#pragma exclude_renderers glcore gles gles3 ps4 ps5 
		#pragma multi_compile_instancing
		#pragma instancing_options renderinglayer

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
            float3 NormalTS;
            float NormalAlpha;
            float Metallic;
            float Occlusion;
            float Smoothness;
            float MAOSAlpha;
			float3 Emission;
        };
		ENDHLSL

		
        Pass
		{
			
			Name "DBufferProjector"
			Tags { "LightMode"="DBufferProjector" }

            Stencil
            {
            	Ref [_DecalStencilRef]
            	WriteMask [_DecalStencilWriteMask]
            	Comp Always
            	Pass Replace
            }


			Cull Front
			ZWrite Off
			ZTest Greater

			Blend 0 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 1 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 2 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 3 Zero OneMinusSrcColor

			ColorMask[_DecalColorMask0]
			ColorMask[_DecalColorMask1] 1
			ColorMask[_DecalColorMask2] 2
			ColorMask[_DecalColorMask3] 3

			HLSLPROGRAM

            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_ALBEDO
            #pragma shader_feature_local_fragment _COLORMAP
            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_NORMAL
            #define _MATERIAL_AFFECTS_EMISSION
            #pragma shader_feature_local_fragment _EMISSIVEMAP
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_MASKMAP
            #pragma shader_feature_local_fragment _MASKMAP
            #define ASE_SRP_VERSION 140009
            #define ASE_USING_SAMPLING_MACROS 1


            #pragma vertex Vert
            #pragma fragment Frag

			#pragma multi_compile_fragment DECALS_3RT DECALS_4RT
			#pragma multi_compile_fragment _ DECAL_SURFACE_GRADIENT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			#define SHADERPASS SHADERPASS_DBUFFER_PROJECTOR

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/Decal.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalPrepassBuffer.hlsl"

			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
				
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

      		struct PackedVaryingsToPS
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_RELATIVE_WORLD_POS)
				float3 positionRWS : TEXCOORD0;
				#endif
				
                UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor_ST;
            float _AntiAlias;
            float _AntiAliasPower;
            float _DrawOrder;
			float _NormalBlendSrc;
			float _MaskBlendSrc;
			float _DecalBlend;
			int   _DecalMeshBiasType;
            float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
            float _DecalStencilWriteMask;
            float _DecalStencilRef;
			#ifdef _MATERIAL_AFFECTS_ALBEDO
            float _AffectAlbedo;
			#endif
			#ifdef _MATERIAL_AFFECTS_NORMAL
            float _AffectNormal;
			#endif
            #ifdef _MATERIAL_AFFECTS_MASKMAP
            float _AffectAO;
			float _AffectMetal;
            float _AffectSmoothness;
			#endif
			#ifdef _MATERIAL_AFFECTS_EMISSION
            float _AffectEmission;
			#endif
            float _DecalColorMask0;
            float _DecalColorMask1;
            float _DecalColorMask2;
            float _DecalColorMask3;
            CBUFFER_END

			TEXTURE2D(_BaseColor);
			SAMPLER(sampler_BaseColor);


            #if (SHADERPASS == SHADERPASS_DBUFFER_MESH) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_MESH)
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT // Always present as we require it also in case of anisotropic lighting
            #define ATTRIBUTES_NEED_TEXCOORD0

            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_TANGENT_TO_WORLD
            #define VARYINGS_NEED_TEXCOORD0
            #endif

			
            void GetSurfaceData(SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, PositionInputs posInput, float angleFadeFactor, out DecalSurfaceData surfaceData)
            {
                #if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)
                    float4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
                    float fadeFactor = clamp(normalToWorld[0][3], 0.0f, 1.0f) * angleFadeFactor;
                    float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
                    float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);
                    fragInputs.texCoord0.xy = fragInputs.texCoord0.xy * scale + offset;
                    fragInputs.texCoord1.xy = fragInputs.texCoord1.xy * scale + offset;
                    fragInputs.texCoord2.xy = fragInputs.texCoord2.xy * scale + offset;
                    fragInputs.texCoord3.xy = fragInputs.texCoord3.xy * scale + offset;
                    fragInputs.positionRWS = posInput.positionWS;
                    fragInputs.tangentToWorld[2].xyz = TransformObjectToWorldDir(float3(0, 1, 0));
                    fragInputs.tangentToWorld[1].xyz = TransformObjectToWorldDir(float3(0, 0, 1));
                #else
                    #ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                    #endif

                    float fadeFactor = 1.0;
                #endif

                ZERO_INITIALIZE(DecalSurfaceData, surfaceData);

                #ifdef _MATERIAL_AFFECTS_EMISSION
                #endif

                #ifdef _MATERIAL_AFFECTS_ALBEDO
                    surfaceData.baseColor.xyz = surfaceDescription.BaseColor;
                    surfaceData.baseColor.w = surfaceDescription.Alpha * fadeFactor;
                #endif

                #ifdef _MATERIAL_AFFECTS_NORMAL
                    #ifdef DECAL_SURFACE_GRADIENT
                        #if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)
                            float3x3 tangentToWorld = transpose((float3x3)normalToWorld);
                        #else
                            float3x3 tangentToWorld = fragInputs.tangentToWorld;
                        #endif

                        surfaceData.normalWS.xyz = SurfaceGradientFromTangentSpaceNormalAndFromTBN(surfaceDescription.NormalTS.xyz, tangentToWorld[0], tangentToWorld[1]);
                    #else
                        #if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR)
                            surfaceData.normalWS.xyz = mul((float3x3)normalToWorld, surfaceDescription.NormalTS);
                        #elif (SHADERPASS == SHADERPASS_DBUFFER_MESH) || (SHADERPASS == SHADERPASS_FORWARD_PREVIEW)

                            surfaceData.normalWS.xyz = normalize(TransformTangentToWorld(surfaceDescription.NormalTS, fragInputs.tangentToWorld));
                        #endif
                    #endif

                    surfaceData.normalWS.w = surfaceDescription.NormalAlpha * fadeFactor;
                #else
                    #if (SHADERPASS == SHADERPASS_FORWARD_PREVIEW)
                        #ifdef DECAL_SURFACE_GRADIENT
                            surfaceData.normalWS.xyz = float3(0.0, 0.0, 0.0);
                        #else
                            surfaceData.normalWS.xyz = normalize(TransformTangentToWorld(float3(0.0, 0.0, 0.1), fragInputs.tangentToWorld));
                        #endif
                    #endif
                #endif

                #ifdef _MATERIAL_AFFECTS_MASKMAP
                    surfaceData.mask.z = surfaceDescription.Smoothness;
                    surfaceData.mask.w = surfaceDescription.MAOSAlpha * fadeFactor;

                    #ifdef DECALS_4RT
                        surfaceData.mask.x = surfaceDescription.Metallic;
                        surfaceData.mask.y = surfaceDescription.Occlusion;
                        surfaceData.MAOSBlend.x = surfaceDescription.MAOSAlpha * fadeFactor;
                        surfaceData.MAOSBlend.y = surfaceDescription.MAOSAlpha * fadeFactor;
                    #endif

                #endif
            }

			PackedVaryingsToPS Vert(AttributesMesh inputMesh  )
			{
				PackedVaryingsToPS output;

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( output );

				inputMesh.tangentOS = float4( 1, 0, 0, -1);
				inputMesh.normalOS = float3( 0, 1, 0 );

				

				inputMesh.normalOS = inputMesh.normalOS;
				inputMesh.tangentOS = inputMesh.tangentOS;

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);
				float4 tangentWS = float4(TransformObjectToWorldDir(inputMesh.tangentOS.xyz), inputMesh.tangentOS.w);

				output.positionCS = TransformWorldToHClip(positionRWS);
				#if defined(ASE_NEEDS_FRAG_RELATIVE_WORLD_POS)
				output.positionRWS = positionRWS;
				#endif

				return output;
			}

			void Frag( PackedVaryingsToPS packedInput,
			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_DBUFFER_MESH)
				OUTPUT_DBUFFER(outDBuffer)
			#else
				out float4 outEmissive : SV_Target0
			#endif
			
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);

				FragInputs input;
                ZERO_INITIALIZE(FragInputs, input);
                input.tangentToWorld = k_identity3x3;
				#if defined(ASE_NEEDS_FRAG_RELATIVE_WORLD_POS)
				input.positionRWS = packedInput.positionRWS;
				#endif

                input.positionSS = packedInput.positionCS;

				DecalSurfaceData surfaceData;
				float clipValue = 1.0;
				float angleFadeFactor = 1.0;

				PositionInputs posInput;
			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)

				float depth = LoadCameraDepth(input.positionSS.xy);
				posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);

				DecalPrepassData material;
				ZERO_INITIALIZE(DecalPrepassData, material);
				if (_EnableDecalLayers)
				{
					uint decalLayerMask = uint(UNITY_ACCESS_INSTANCED_PROP(Decal, _DecalLayerMaskFromDecal).x);

					DecodeFromDecalPrepass(posInput.positionSS, material);

					if ((decalLayerMask & material.decalLayerMask) == 0)
						clipValue -= 2.0;
				}


				float3 positionDS = TransformWorldToObject(posInput.positionWS);
				positionDS = positionDS * float3(1.0, -1.0, 1.0) + float3(0.5, 0.5, 0.5);
				if (!(all(positionDS.xyz > 0.0f) && all(1.0f - positionDS.xyz > 0.0f)))
				{
					clipValue -= 2.0;
				}

			#ifndef SHADER_API_METAL
				clip(clipValue);
			#else
				if (clipValue > 0.0)
				{
			#endif

				float4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
				float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
				float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);
				positionDS.xz = positionDS.xz * scale + offset;

				input.texCoord0.xy = positionDS.xz;
				input.texCoord1.xy = positionDS.xz;
				input.texCoord2.xy = positionDS.xz;
				input.texCoord3.xy = positionDS.xz;

				float3 V = GetWorldSpaceNormalizeViewDir(posInput.positionWS);
				if (_EnableDecalLayers)
				{
					float2 angleFade = float2(normalToWorld[1][3], normalToWorld[2][3]);

					if (angleFade.x > 0.0f)
					{
						float3 decalNormal = float3(normalToWorld[0].z, normalToWorld[1].z, normalToWorld[2].z);
                        angleFadeFactor = DecodeAngleFade(dot(material.geomNormalWS, decalNormal), angleFade);
					}
				}

			#else
				posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS.xyz, uint2(0, 0));
				#if defined(ASE_NEEDS_FRAG_RELATIVE_WORLD_POS)
					float3 V = GetWorldSpaceNormalizeViewDir(input.positionRWS);
				#else
					float3 V = float3(1.0, 1.0, 1.0);
				#endif
			#endif

				float3 positionWS = GetAbsolutePositionWS( posInput.positionWS );
				float3 positionRWS = posInput.positionWS;

				float3 worldTangent = TransformObjectToWorldDir(float3(1, 0, 0));
				float3 worldNormal = TransformObjectToWorldDir(float3(0, 1, 0));
				float3 worldBitangent = TransformObjectToWorldDir(float3(0, 0, 1));

				float4 texCoord0 = input.texCoord0;
				float4 texCoord1 = input.texCoord1;
				float4 texCoord2 = input.texCoord2;
				float4 texCoord3 = input.texCoord3;

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float2 uv_BaseColor = texCoord0.xy * _BaseColor_ST.xy + _BaseColor_ST.zw;
				float4 tex2DNode5 = SAMPLE_TEXTURE2D( _BaseColor, sampler_BaseColor, uv_BaseColor );
				
				float temp_output_3_0_g3 = ( tex2DNode5.a - _AntiAlias );
				float lerpResult17 = lerp( tex2DNode5.a , saturate( ( temp_output_3_0_g3 / fwidth( temp_output_3_0_g3 ) ) ) , _AntiAliasPower);
				

				surfaceDescription.BaseColor = tex2DNode5.rgb;
				surfaceDescription.Alpha = lerpResult17;
				surfaceDescription.NormalTS = tex2DNode5.rgb;
				surfaceDescription.NormalAlpha = lerpResult17;
				surfaceDescription.Metallic = 0;
				surfaceDescription.Occlusion = 1;
				surfaceDescription.Smoothness = 0.5;
				surfaceDescription.MAOSAlpha = 1;
				surfaceDescription.Emission = float3( 0, 0, 0 );

				GetSurfaceData(surfaceDescription, input, V, posInput, angleFadeFactor, surfaceData);

			#if ((SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)) && defined(SHADER_API_METAL)
				} // if (clipValue > 0.0)

				clip(clipValue);
			#endif

			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_DBUFFER_MESH)
				ENCODE_INTO_DBUFFER(surfaceData, outDBuffer);
			#else
				// Emissive need to be pre-exposed
				outEmissive.rgb = surfaceData.emissive * GetCurrentExposureMultiplier();
				outEmissive.a = 1.0;
			#endif
			}

            ENDHLSL
        }

		
        Pass
		{
			
			Name "DecalProjectorForwardEmissive"
			Tags { "LightMode"="DecalProjectorForwardEmissive" }

			Stencil
			{
				Ref [_DecalStencilRef]
				WriteMask [_DecalStencilWriteMask]
				Comp Always
				Pass Replace
			}


			Cull Front
			ZWrite Off
			ZTest Greater

			Blend 0 SrcAlpha One

			HLSLPROGRAM

            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_ALBEDO
            #pragma shader_feature_local_fragment _COLORMAP
            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_NORMAL
            #define _MATERIAL_AFFECTS_EMISSION
            #pragma shader_feature_local_fragment _EMISSIVEMAP
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_MASKMAP
            #pragma shader_feature_local_fragment _MASKMAP
            #define ASE_SRP_VERSION 140009
            #define ASE_USING_SAMPLING_MACROS 1


            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			#define SHADERPASS SHADERPASS_FORWARD_EMISSIVE_PROJECTOR

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/Decal.hlsl"

			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalPrepassBuffer.hlsl"

			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

      		struct PackedVaryingsToPS
			{
				float4 positionCS : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_RELATIVE_WORLD_POS)
				float3 positionRWS : TEXCOORD0;
				#endif
				
                UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            CBUFFER_START(UnityPerMaterial)
			float4 _BaseColor_ST;
			float _AntiAlias;
			float _AntiAliasPower;
			float _DrawOrder;
			float _NormalBlendSrc;
			float _MaskBlendSrc;
			float _DecalBlend;
			int   _DecalMeshBiasType;
			float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
            float _DecalStencilWriteMask;
            float _DecalStencilRef;
            #ifdef _MATERIAL_AFFECTS_ALBEDO
            float _AffectAlbedo;
			#endif
            #ifdef _MATERIAL_AFFECTS_NORMAL
            float _AffectNormal;
			#endif
            #ifdef _MATERIAL_AFFECTS_MASKMAP
            float _AffectAO;
			float _AffectMetal;
            float _AffectSmoothness;
			#endif
            #ifdef _MATERIAL_AFFECTS_EMISSION
            float _AffectEmission;
			#endif
            float _DecalColorMask0;
            float _DecalColorMask1;
            float _DecalColorMask2;
            float _DecalColorMask3;
            CBUFFER_END

			TEXTURE2D(_BaseColor);
			SAMPLER(sampler_BaseColor);


			
            void GetSurfaceData(SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, PositionInputs posInput, float angleFadeFactor, out DecalSurfaceData surfaceData)
            {
                #if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)
                    float4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
                    float fadeFactor = clamp(normalToWorld[0][3], 0.0f, 1.0f) * angleFadeFactor;
                    float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
                    float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);
                    fragInputs.texCoord0.xy = fragInputs.texCoord0.xy * scale + offset;
                    fragInputs.texCoord1.xy = fragInputs.texCoord1.xy * scale + offset;
                    fragInputs.texCoord2.xy = fragInputs.texCoord2.xy * scale + offset;
                    fragInputs.texCoord3.xy = fragInputs.texCoord3.xy * scale + offset;
                    fragInputs.positionRWS = posInput.positionWS;
                    fragInputs.tangentToWorld[2].xyz = TransformObjectToWorldDir(float3(0, 1, 0));
                    fragInputs.tangentToWorld[1].xyz = TransformObjectToWorldDir(float3(0, 0, 1));
                #else
                    #ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                    #endif

                    float fadeFactor = 1.0;
                #endif

                ZERO_INITIALIZE(DecalSurfaceData, surfaceData);

                #ifdef _MATERIAL_AFFECTS_EMISSION
                    surfaceData.emissive.rgb = surfaceDescription.Emission.rgb * fadeFactor;
                #endif
            }

			PackedVaryingsToPS Vert(AttributesMesh inputMesh  )
			{
				PackedVaryingsToPS output;

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( output );

				inputMesh.tangentOS = float4( 1, 0, 0, -1);
				inputMesh.normalOS = float3( 0, 1, 0 );

				

				inputMesh.normalOS = inputMesh.normalOS;
				inputMesh.tangentOS = inputMesh.tangentOS;

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);
				float4 tangentWS = float4(TransformObjectToWorldDir(inputMesh.tangentOS.xyz), inputMesh.tangentOS.w);

				output.positionCS = TransformWorldToHClip(positionRWS);
				#if defined(ASE_NEEDS_FRAG_RELATIVE_WORLD_POS)
				output.positionRWS = positionRWS;
				#endif

				return output;
			}

			void Frag( PackedVaryingsToPS packedInput,
			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_DBUFFER_MESH)
				OUTPUT_DBUFFER(outDBuffer)
			#else
				out float4 outEmissive : SV_Target0
			#endif
			
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);

				FragInputs input;
                ZERO_INITIALIZE(FragInputs, input);
                input.tangentToWorld = k_identity3x3;
				#if defined(ASE_NEEDS_FRAG_RELATIVE_WORLD_POS)
				input.positionRWS = packedInput.positionRWS;
				#endif

                input.positionSS = packedInput.positionCS;

				DecalSurfaceData surfaceData;
				float clipValue = 1.0;
				float angleFadeFactor = 1.0;

				PositionInputs posInput;
			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)

				float depth = LoadCameraDepth(input.positionSS.xy);
				#if (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR) && UNITY_REVERSED_Z
					depth = IsSky(depth) ? UNITY_NEAR_CLIP_VALUE : depth;
				#endif

				posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);

				DecalPrepassData material;
				ZERO_INITIALIZE(DecalPrepassData, material);
				if (_EnableDecalLayers)
				{
					uint decalLayerMask = uint(UNITY_ACCESS_INSTANCED_PROP(Decal, _DecalLayerMaskFromDecal).x);

					DecodeFromDecalPrepass(posInput.positionSS, material);

					if ((decalLayerMask & material.decalLayerMask) == 0)
						clipValue -= 2.0;
				}


				float3 positionDS = TransformWorldToObject(posInput.positionWS);
				positionDS = positionDS * float3(1.0, -1.0, 1.0) + float3(0.5, 0.5, 0.5);
				if (!(all(positionDS.xyz > 0.0f) && all(1.0f - positionDS.xyz > 0.0f)))
				{
					clipValue -= 2.0;
				}

			#ifndef SHADER_API_METAL
				clip(clipValue);
			#else
				if (clipValue > 0.0)
				{
			#endif

				float4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
				float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
				float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);
				positionDS.xz = positionDS.xz * scale + offset;

				input.texCoord0.xy = positionDS.xz;
				input.texCoord1.xy = positionDS.xz;
				input.texCoord2.xy = positionDS.xz;
				input.texCoord3.xy = positionDS.xz;

				float3 V = GetWorldSpaceNormalizeViewDir(posInput.positionWS);
				if (_EnableDecalLayers)
				{
					float2 angleFade = float2(normalToWorld[1][3], normalToWorld[2][3]);

					if (angleFade.x > 0.0f)
					{
						float3 decalNormal = float3(normalToWorld[0].z, normalToWorld[1].z, normalToWorld[2].z);
                        angleFadeFactor = DecodeAngleFade(dot(material.geomNormalWS, decalNormal), angleFade);
					}
				}

			#else
				posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS.xyz, uint2(0, 0));
				#if defined(ASE_NEEDS_FRAG_RELATIVE_WORLD_POS)
					float3 V = GetWorldSpaceNormalizeViewDir(input.positionRWS);
				#else
					float3 V = float3(1.0, 1.0, 1.0);
				#endif
			#endif

				float3 positionWS = GetAbsolutePositionWS( posInput.positionWS );
				float3 positionRWS = posInput.positionWS;

				float3 worldTangent = TransformObjectToWorldDir(float3(1, 0, 0));
				float3 worldNormal = TransformObjectToWorldDir(float3(0, 1, 0));
				float3 worldBitangent = TransformObjectToWorldDir(float3(0, 0, 1));

				float4 texCoord0 = input.texCoord0;
				float4 texCoord1 = input.texCoord1;
				float4 texCoord2 = input.texCoord2;
				float4 texCoord3 = input.texCoord3;

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float2 uv_BaseColor = texCoord0.xy * _BaseColor_ST.xy + _BaseColor_ST.zw;
				float4 tex2DNode5 = SAMPLE_TEXTURE2D( _BaseColor, sampler_BaseColor, uv_BaseColor );
				
				float temp_output_3_0_g3 = ( tex2DNode5.a - _AntiAlias );
				float lerpResult17 = lerp( tex2DNode5.a , saturate( ( temp_output_3_0_g3 / fwidth( temp_output_3_0_g3 ) ) ) , _AntiAliasPower);
				

				surfaceDescription.BaseColor = tex2DNode5.rgb;
				surfaceDescription.Alpha = lerpResult17;
				surfaceDescription.NormalTS = tex2DNode5.rgb;
				surfaceDescription.NormalAlpha = lerpResult17;
				surfaceDescription.Metallic = 0;
				surfaceDescription.Occlusion = 1;
				surfaceDescription.Smoothness = 0.5;
				surfaceDescription.MAOSAlpha = 1;
				surfaceDescription.Emission = float3( 0, 0, 0 );

				GetSurfaceData(surfaceDescription, input, V, posInput, angleFadeFactor, surfaceData);

			#if ((SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)) && defined(SHADER_API_METAL)
				}

				clip(clipValue);
			#endif

			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_DBUFFER_MESH)
				ENCODE_INTO_DBUFFER(surfaceData, outDBuffer);
			#else
				// Emissive need to be pre-exposed
				outEmissive.rgb = surfaceData.emissive * GetCurrentExposureMultiplier();
				outEmissive.a = 1.0;
			#endif
			}

            ENDHLSL
        }

		
        Pass
		{
			
			Name "DBufferMesh"
			Tags { "LightMode"="DBufferMesh" }


			Stencil
			{
				Ref [_DecalStencilRef]
				WriteMask [_DecalStencilWriteMask]
				Comp Always
				Pass Replace
			}


			ZWrite Off
			ZTest LEqual

			Blend 0 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 1 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 2 SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
			Blend 3 Zero OneMinusSrcColor

			ColorMask[_DecalColorMask0]
			ColorMask[_DecalColorMask1] 1
			ColorMask[_DecalColorMask2] 2
			ColorMask[_DecalColorMask3] 3

            HLSLPROGRAM

            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_ALBEDO
            #pragma shader_feature_local_fragment _COLORMAP
            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_NORMAL
            #define _MATERIAL_AFFECTS_EMISSION
            #pragma shader_feature_local_fragment _EMISSIVEMAP
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_MASKMAP
            #pragma shader_feature_local_fragment _MASKMAP
            #define ASE_SRP_VERSION 140009
            #define ASE_USING_SAMPLING_MACROS 1


            #pragma vertex Vert
            #pragma fragment Frag

			#pragma multi_compile_fragment DECALS_3RT DECALS_4RT
			#pragma multi_compile_fragment _ DECAL_SURFACE_GRADIENT

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			#define SHADERPASS SHADERPASS_DBUFFER_MESH

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/Decal.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalPrepassBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/DecalMeshBiasTypeEnum.cs.hlsl"

			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv0 : TEXCOORD0;
				
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			struct PackedVaryingsToPS
			{
				float4 positionCS : SV_POSITION;
                float3 positionRWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float4 uv0 : TEXCOORD3;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor_ST;
            float _AntiAlias;
            float _AntiAliasPower;
            float _DrawOrder;
			float _NormalBlendSrc;
			float _MaskBlendSrc;
			float _DecalBlend;
			int   _DecalMeshBiasType;
            float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
            float _DecalStencilWriteMask;
            float _DecalStencilRef;
            #ifdef _MATERIAL_AFFECTS_ALBEDO
            float _AffectAlbedo;
			#endif
            #ifdef _MATERIAL_AFFECTS_NORMAL
            float _AffectNormal;
			#endif
            #ifdef _MATERIAL_AFFECTS_MASKMAP
            float _AffectAO;
			float _AffectMetal;
            float _AffectSmoothness;
			#endif
            #ifdef _MATERIAL_AFFECTS_EMISSION
            float _AffectEmission;
			#endif
            float _DecalColorMask0;
            float _DecalColorMask1;
            float _DecalColorMask2;
            float _DecalColorMask3;
            CBUFFER_END

	   		TEXTURE2D(_BaseColor);
	   		SAMPLER(sampler_BaseColor);


			
            void GetSurfaceData(SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, PositionInputs posInput, float angleFadeFactor, out DecalSurfaceData surfaceData)
            {
                #if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)
                    float4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
                    float fadeFactor = clamp(normalToWorld[0][3], 0.0f, 1.0f) * angleFadeFactor;
                    float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
                    float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);
                    fragInputs.texCoord0.xy = fragInputs.texCoord0.xy * scale + offset;
                    fragInputs.texCoord1.xy = fragInputs.texCoord1.xy * scale + offset;
                    fragInputs.texCoord2.xy = fragInputs.texCoord2.xy * scale + offset;
                    fragInputs.texCoord3.xy = fragInputs.texCoord3.xy * scale + offset;
                    fragInputs.positionRWS = posInput.positionWS;
                    fragInputs.tangentToWorld[2].xyz = TransformObjectToWorldDir(float3(0, 1, 0));
                    fragInputs.tangentToWorld[1].xyz = TransformObjectToWorldDir(float3(0, 0, 1));
                #else
                    #ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
                    #endif

                    float fadeFactor = 1.0;
                #endif

                ZERO_INITIALIZE(DecalSurfaceData, surfaceData);

                #ifdef _MATERIAL_AFFECTS_EMISSION
                #endif

                #ifdef _MATERIAL_AFFECTS_ALBEDO
                    surfaceData.baseColor.xyz = surfaceDescription.BaseColor;
                    surfaceData.baseColor.w = surfaceDescription.Alpha * fadeFactor;
                #endif

                #ifdef _MATERIAL_AFFECTS_NORMAL
                    #ifdef DECAL_SURFACE_GRADIENT
                        #if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)
                            float3x3 tangentToWorld = transpose((float3x3)normalToWorld);
                        #else
                            float3x3 tangentToWorld = fragInputs.tangentToWorld;
                        #endif

                        surfaceData.normalWS.xyz = SurfaceGradientFromTangentSpaceNormalAndFromTBN(surfaceDescription.NormalTS.xyz, tangentToWorld[0], tangentToWorld[1]);
                    #else
                        #if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR)
                            surfaceData.normalWS.xyz = mul((float3x3)normalToWorld, surfaceDescription.NormalTS);
                        #elif (SHADERPASS == SHADERPASS_DBUFFER_MESH) || (SHADERPASS == SHADERPASS_FORWARD_PREVIEW)

                            surfaceData.normalWS.xyz = normalize(TransformTangentToWorld(surfaceDescription.NormalTS, fragInputs.tangentToWorld));
                        #endif
                    #endif

                    surfaceData.normalWS.w = surfaceDescription.NormalAlpha * fadeFactor;
                #else
                    #if (SHADERPASS == SHADERPASS_FORWARD_PREVIEW)
                        #ifdef DECAL_SURFACE_GRADIENT
                            surfaceData.normalWS.xyz = float3(0.0, 0.0, 0.0);
                        #else
                            surfaceData.normalWS.xyz = normalize(TransformTangentToWorld(float3(0.0, 0.0, 0.1), fragInputs.tangentToWorld));
                        #endif
                    #endif
                #endif

                #ifdef _MATERIAL_AFFECTS_MASKMAP
                    surfaceData.mask.z = surfaceDescription.Smoothness;
                    surfaceData.mask.w = surfaceDescription.MAOSAlpha * fadeFactor;

                    #ifdef DECALS_4RT
                        surfaceData.mask.x = surfaceDescription.Metallic;
                        surfaceData.mask.y = surfaceDescription.Occlusion;
                        surfaceData.MAOSBlend.x = surfaceDescription.MAOSAlpha * fadeFactor;
                        surfaceData.MAOSBlend.y = surfaceDescription.MAOSAlpha * fadeFactor;
                    #endif

                #endif
            }

			PackedVaryingsToPS Vert(AttributesMesh inputMesh  )
			{
				PackedVaryingsToPS output;

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				inputMesh.tangentOS = float4( 1, 0, 0, -1);
				inputMesh.normalOS = float3( 0, 1, 0 );

				

				inputMesh.normalOS = inputMesh.normalOS;
				inputMesh.tangentOS = inputMesh.tangentOS;

				float3 worldSpaceBias = 0.0f;

				if (_DecalMeshBiasType == DECALMESHDEPTHBIASTYPE_VIEW_BIAS)
				{
					float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
					float3 V = GetWorldSpaceNormalizeViewDir(positionRWS);
					worldSpaceBias = V * (_DecalMeshViewBias);
				}

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS) + worldSpaceBias;
				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);
				float4 tangentWS = float4(TransformObjectToWorldDir(inputMesh.tangentOS.xyz), inputMesh.tangentOS.w);

				output.positionRWS.xyz = positionRWS;
				output.positionCS = TransformWorldToHClip(positionRWS);
				output.normalWS.xyz = normalWS;
				output.tangentWS.xyzw = tangentWS;
				output.uv0.xyzw = inputMesh.uv0;

				if (_DecalMeshBiasType == DECALMESHDEPTHBIASTYPE_DEPTH_BIAS)
				{
					#if UNITY_REVERSED_Z
						output.positionCS.z -= _DecalMeshDepthBias;
					#else
						output.positionCS.z += _DecalMeshDepthBias;
					#endif
				}


				return output;
			}

			void Frag(  PackedVaryingsToPS packedInput,
			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_DBUFFER_MESH)
				OUTPUT_DBUFFER(outDBuffer)
			#else
				out float4 outEmissive : SV_Target0
			#endif
			
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);

                FragInputs input;
                ZERO_INITIALIZE(FragInputs, input);

                input.tangentToWorld = k_identity3x3;
                input.positionSS = packedInput.positionCS;

                input.positionRWS = packedInput.positionRWS.xyz;

                input.tangentToWorld = BuildTangentToWorld(packedInput.tangentWS.xyzw, packedInput.normalWS.xyz);
                input.texCoord0 = packedInput.uv0.xyzw;

				DecalSurfaceData surfaceData;
				float clipValue = 1.0;
				float angleFadeFactor = 1.0;

				PositionInputs posInput;
			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)

				float depth = LoadCameraDepth(input.positionSS.xy);
				posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);

				DecalPrepassData material;
				ZERO_INITIALIZE(DecalPrepassData, material);
				if (_EnableDecalLayers)
				{
					uint decalLayerMask = uint(UNITY_ACCESS_INSTANCED_PROP(Decal, _DecalLayerMaskFromDecal).x);

					DecodeFromDecalPrepass(posInput.positionSS, material);

					if ((decalLayerMask & material.decalLayerMask) == 0)
						clipValue -= 2.0;
				}

				float3 positionDS = TransformWorldToObject(posInput.positionWS);
				positionDS = positionDS * float3(1.0, -1.0, 1.0) + float3(0.5, 0.5, 0.5);
				if (!(all(positionDS.xyz > 0.0f) && all(1.0f - positionDS.xyz > 0.0f)))
				{
					clipValue -= 2.0;
				}

			#ifndef SHADER_API_METAL
				clip(clipValue);
			#else
				if (clipValue > 0.0)
				{
			#endif

				float4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
				float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
				float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);
				positionDS.xz = positionDS.xz * scale + offset;

				input.texCoord0.xy = positionDS.xz;
				input.texCoord1.xy = positionDS.xz;
				input.texCoord2.xy = positionDS.xz;
				input.texCoord3.xy = positionDS.xz;

				float3 V = GetWorldSpaceNormalizeViewDir(posInput.positionWS);

				if (_EnableDecalLayers)
				{
					float2 angleFade = float2(normalToWorld[1][3], normalToWorld[2][3]);
					if (angleFade.x > 0.0f)
					{
						float3 decalNormal = float3(normalToWorld[0].z, normalToWorld[1].z, normalToWorld[2].z);
                        angleFadeFactor = DecodeAngleFade(dot(material.geomNormalWS, decalNormal), angleFade);
					}
				}

			#else
				posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS.xyz, uint2(0, 0));
				float3 V = GetWorldSpaceNormalizeViewDir(input.positionRWS);
			#endif

				float3 positionWS = GetAbsolutePositionWS( posInput.positionWS );
				float3 positionRWS = posInput.positionWS;

				float3 worldTangent = TransformObjectToWorldDir(float3(1, 0, 0));
				float3 worldNormal = TransformObjectToWorldDir(float3(0, 1, 0));
				float3 worldBitangent = TransformObjectToWorldDir(float3(0, 0, 1));

				float4 texCoord0 = input.texCoord0;
				float4 texCoord1 = input.texCoord1;
				float4 texCoord2 = input.texCoord2;
				float4 texCoord3 = input.texCoord3;

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float2 uv_BaseColor = texCoord0.xy * _BaseColor_ST.xy + _BaseColor_ST.zw;
				float4 tex2DNode5 = SAMPLE_TEXTURE2D( _BaseColor, sampler_BaseColor, uv_BaseColor );
				
				float temp_output_3_0_g3 = ( tex2DNode5.a - _AntiAlias );
				float lerpResult17 = lerp( tex2DNode5.a , saturate( ( temp_output_3_0_g3 / fwidth( temp_output_3_0_g3 ) ) ) , _AntiAliasPower);
				

				surfaceDescription.BaseColor = tex2DNode5.rgb;
				surfaceDescription.Alpha = lerpResult17;
				surfaceDescription.NormalTS = tex2DNode5.rgb;
				surfaceDescription.NormalAlpha = lerpResult17;
				surfaceDescription.Metallic = 0;
				surfaceDescription.Occlusion = 1;
				surfaceDescription.Smoothness = 0.5;
				surfaceDescription.MAOSAlpha = 1;
				surfaceDescription.Emission = float3( 0, 0, 0 );

				GetSurfaceData(surfaceDescription, input, V, posInput, angleFadeFactor, surfaceData);

			#if ((SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)) && defined(SHADER_API_METAL)
				}

				clip(clipValue);
			#endif

			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_DBUFFER_MESH)
				ENCODE_INTO_DBUFFER(surfaceData, outDBuffer);
			#else
				outEmissive.rgb = surfaceData.emissive * GetCurrentExposureMultiplier();
				outEmissive.a = 1.0;
			#endif
			}
            ENDHLSL
        }

		
        Pass
		{
			
			Name "DecalMeshForwardEmissive"
			Tags { "LightMode"="DecalMeshForwardEmissive" }

			Stencil
			{
				Ref [_DecalStencilRef]
				WriteMask [_DecalStencilWriteMask]
				Comp Always
				Pass Replace
			}


			ZWrite Off
			ZTest LEqual

			Blend 0 SrcAlpha One

            HLSLPROGRAM

            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_ALBEDO
            #pragma shader_feature_local_fragment _COLORMAP
            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_NORMAL
            #define _MATERIAL_AFFECTS_EMISSION
            #pragma shader_feature_local_fragment _EMISSIVEMAP
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_MASKMAP
            #pragma shader_feature_local_fragment _MASKMAP
            #define ASE_SRP_VERSION 140009
            #define ASE_USING_SAMPLING_MACROS 1


            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"

			#define SHADERPASS SHADERPASS_FORWARD_EMISSIVE_MESH

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/Decal.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalPrepassBuffer.hlsl"

			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


            struct AttributesMesh
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float4 uv0 : TEXCOORD0;
				
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			struct PackedVaryingsToPS
			{
				float4 positionCS : SV_POSITION;
                float3 positionRWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float4 uv0 : TEXCOORD3;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor_ST;
            float _AntiAlias;
            float _AntiAliasPower;
            float _DrawOrder;
			float _NormalBlendSrc;
			float _MaskBlendSrc;
			float _DecalBlend;
			int   _DecalMeshBiasType;
            float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
            float _DecalStencilWriteMask;
            float _DecalStencilRef;
            #ifdef _MATERIAL_AFFECTS_ALBEDO
            float _AffectAlbedo;
			#endif
            #ifdef _MATERIAL_AFFECTS_NORMAL
            float _AffectNormal;
			#endif
            #ifdef _MATERIAL_AFFECTS_MASKMAP
            float _AffectAO;
			float _AffectMetal;
            float _AffectSmoothness;
			#endif
            #ifdef _MATERIAL_AFFECTS_EMISSION
            float _AffectEmission;
			#endif
            float _DecalColorMask0;
            float _DecalColorMask1;
            float _DecalColorMask2;
            float _DecalColorMask3;
            CBUFFER_END

	   		TEXTURE2D(_BaseColor);
	   		SAMPLER(sampler_BaseColor);


			
			void GetSurfaceData(SurfaceDescription surfaceDescription, FragInputs fragInputs, float3 V, PositionInputs posInput, float angleFadeFactor, out DecalSurfaceData surfaceData)
			{
				#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)
					float4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
					float fadeFactor = clamp(normalToWorld[0][3], 0.0f, 1.0f) * angleFadeFactor;
					float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
					float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);
					fragInputs.texCoord0.xy = fragInputs.texCoord0.xy * scale + offset;
					fragInputs.texCoord1.xy = fragInputs.texCoord1.xy * scale + offset;
					fragInputs.texCoord2.xy = fragInputs.texCoord2.xy * scale + offset;
					fragInputs.texCoord3.xy = fragInputs.texCoord3.xy * scale + offset;
					fragInputs.positionRWS = posInput.positionWS;
					fragInputs.tangentToWorld[2].xyz = TransformObjectToWorldDir(float3(0, 1, 0));
					fragInputs.tangentToWorld[1].xyz = TransformObjectToWorldDir(float3(0, 0, 1));
				#else
					#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition(ComputeFadeMaskSeed(V, posInput.positionSS), unity_LODFade.x);
					#endif

					float fadeFactor = 1.0;
				#endif

				ZERO_INITIALIZE(DecalSurfaceData, surfaceData);

				#ifdef _MATERIAL_AFFECTS_EMISSION
					surfaceData.emissive.rgb = surfaceDescription.Emission.rgb * fadeFactor;
				#endif

				#ifdef _MATERIAL_AFFECTS_ALBEDO
					surfaceData.baseColor.xyz = surfaceDescription.BaseColor;
					surfaceData.baseColor.w = surfaceDescription.Alpha * fadeFactor;
				#endif

				#ifdef _MATERIAL_AFFECTS_NORMAL
					#ifdef DECAL_SURFACE_GRADIENT
						#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)
							float3x3 tangentToWorld = transpose((float3x3)normalToWorld);
						#else
							float3x3 tangentToWorld = fragInputs.tangentToWorld;
						#endif

						surfaceData.normalWS.xyz = SurfaceGradientFromTangentSpaceNormalAndFromTBN(surfaceDescription.NormalTS.xyz, tangentToWorld[0], tangentToWorld[1]);
					#else
						#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR)
							surfaceData.normalWS.xyz = mul((float3x3)normalToWorld, surfaceDescription.NormalTS);
						#elif (SHADERPASS == SHADERPASS_DBUFFER_MESH) || (SHADERPASS == SHADERPASS_FORWARD_PREVIEW)
							surfaceData.normalWS.xyz = normalize(TransformTangentToWorld(surfaceDescription.NormalTS, fragInputs.tangentToWorld));
						#endif
					#endif

					surfaceData.normalWS.w = surfaceDescription.NormalAlpha * fadeFactor;
				#else
					#if (SHADERPASS == SHADERPASS_FORWARD_PREVIEW)
						#ifdef DECAL_SURFACE_GRADIENT
							surfaceData.normalWS.xyz = float3(0.0, 0.0, 0.0);
						#else
							surfaceData.normalWS.xyz = normalize(TransformTangentToWorld(float3(0.0, 0.0, 0.1), fragInputs.tangentToWorld));
						#endif
					#endif
				#endif

				#ifdef _MATERIAL_AFFECTS_MASKMAP
					surfaceData.mask.z = surfaceDescription.Smoothness;
					surfaceData.mask.w = surfaceDescription.MAOSAlpha * fadeFactor;

					#ifdef DECALS_4RT
						surfaceData.mask.x = surfaceDescription.Metallic;
						surfaceData.mask.y = surfaceDescription.Occlusion;
						surfaceData.MAOSBlend.x = surfaceDescription.MAOSAlpha * fadeFactor;
						surfaceData.MAOSBlend.y = surfaceDescription.MAOSAlpha * fadeFactor;
					#endif

				#endif
			}

			PackedVaryingsToPS Vert(AttributesMesh inputMesh  )
			{
				PackedVaryingsToPS output;

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				inputMesh.tangentOS = float4( 1, 0, 0, -1);
				inputMesh.normalOS = float3( 0, 1, 0 );

				

				inputMesh.normalOS = inputMesh.normalOS;
				inputMesh.tangentOS = inputMesh.tangentOS;

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS);
				float3 normalWS = TransformObjectToWorldNormal(inputMesh.normalOS);
				float4 tangentWS = float4(TransformObjectToWorldDir(inputMesh.tangentOS.xyz), inputMesh.tangentOS.w);

				output.positionRWS.xyz = positionRWS;
				output.positionCS = TransformWorldToHClip(positionRWS);
				output.normalWS.xyz = normalWS;
				output.tangentWS.xyzw = tangentWS;
				output.uv0.xyzw = inputMesh.uv0;

				return output;
			}

			void Frag(  PackedVaryingsToPS packedInput,
			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_DBUFFER_MESH)
				OUTPUT_DBUFFER(outDBuffer)
			#else
				out float4 outEmissive : SV_Target0
			#endif
			
			)
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(packedInput);
				UNITY_SETUP_INSTANCE_ID(packedInput);

                FragInputs input;
                ZERO_INITIALIZE(FragInputs, input);

                input.tangentToWorld = k_identity3x3;
                input.positionSS = packedInput.positionCS;

                input.positionRWS = packedInput.positionRWS.xyz;

                input.tangentToWorld = BuildTangentToWorld(packedInput.tangentWS.xyzw, packedInput.normalWS.xyz);
                input.texCoord0 = packedInput.uv0.xyzw;

				DecalSurfaceData surfaceData;
				float clipValue = 1.0;
				float angleFadeFactor = 1.0;

				PositionInputs posInput;
			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)

				float depth = LoadCameraDepth(input.positionSS.xy);
				posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);

				DecalPrepassData material;
				ZERO_INITIALIZE(DecalPrepassData, material);
				if (_EnableDecalLayers)
				{
					uint decalLayerMask = uint(UNITY_ACCESS_INSTANCED_PROP(Decal, _DecalLayerMaskFromDecal).x);

					DecodeFromDecalPrepass(posInput.positionSS, material);

					if ((decalLayerMask & material.decalLayerMask) == 0)
						clipValue -= 2.0;
				}

				float3 positionDS = TransformWorldToObject(posInput.positionWS);
				positionDS = positionDS * float3(1.0, -1.0, 1.0) + float3(0.5, 0.5, 0.5);
				if (!(all(positionDS.xyz > 0.0f) && all(1.0f - positionDS.xyz > 0.0f)))
				{
					clipValue -= 2.0;
				}

			#ifndef SHADER_API_METAL
				clip(clipValue);
			#else
				if (clipValue > 0.0)
				{
			#endif

				float4x4 normalToWorld = UNITY_ACCESS_INSTANCED_PROP(Decal, _NormalToWorld);
				float2 scale = float2(normalToWorld[3][0], normalToWorld[3][1]);
				float2 offset = float2(normalToWorld[3][2], normalToWorld[3][3]);
				positionDS.xz = positionDS.xz * scale + offset;

				input.texCoord0.xy = positionDS.xz;
				input.texCoord1.xy = positionDS.xz;
				input.texCoord2.xy = positionDS.xz;
				input.texCoord3.xy = positionDS.xz;

				float3 V = GetWorldSpaceNormalizeViewDir(posInput.positionWS);

				if (_EnableDecalLayers)
				{
					float2 angleFade = float2(normalToWorld[1][3], normalToWorld[2][3]);
					if (angleFade.x > 0.0f)
					{
						float3 decalNormal = float3(normalToWorld[0].z, normalToWorld[1].z, normalToWorld[2].z);
                        angleFadeFactor = DecodeAngleFade(dot(material.geomNormalWS, decalNormal), angleFade);
					}
				}

			#else
				posInput = GetPositionInput(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS.xyz, uint2(0, 0));
				float3 V = GetWorldSpaceNormalizeViewDir(input.positionRWS);
			#endif

				float3 positionWS = GetAbsolutePositionWS( posInput.positionWS );
				float3 positionRWS = posInput.positionWS;

				float3 worldTangent = TransformObjectToWorldDir(float3(1, 0, 0));
				float3 worldNormal = TransformObjectToWorldDir(float3(0, 1, 0));
				float3 worldBitangent = TransformObjectToWorldDir(float3(0, 0, 1));

				float4 texCoord0 = input.texCoord0;
				float4 texCoord1 = input.texCoord1;
				float4 texCoord2 = input.texCoord2;
				float4 texCoord3 = input.texCoord3;

				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float2 uv_BaseColor = texCoord0.xy * _BaseColor_ST.xy + _BaseColor_ST.zw;
				float4 tex2DNode5 = SAMPLE_TEXTURE2D( _BaseColor, sampler_BaseColor, uv_BaseColor );
				
				float temp_output_3_0_g3 = ( tex2DNode5.a - _AntiAlias );
				float lerpResult17 = lerp( tex2DNode5.a , saturate( ( temp_output_3_0_g3 / fwidth( temp_output_3_0_g3 ) ) ) , _AntiAliasPower);
				

				surfaceDescription.BaseColor = tex2DNode5.rgb;
				surfaceDescription.Alpha = lerpResult17;
				surfaceDescription.NormalTS = tex2DNode5.rgb;
				surfaceDescription.NormalAlpha = lerpResult17;
				surfaceDescription.Metallic = 0;
				surfaceDescription.Occlusion = 1;
				surfaceDescription.Smoothness = 0.5;
				surfaceDescription.MAOSAlpha = 1;
				surfaceDescription.Emission = float3( 0, 0, 0 );

				GetSurfaceData(surfaceDescription, input, V, posInput, angleFadeFactor, surfaceData);

			#if ((SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_FORWARD_EMISSIVE_PROJECTOR)) && defined(SHADER_API_METAL)
				}

				clip(clipValue);
			#endif

			#if (SHADERPASS == SHADERPASS_DBUFFER_PROJECTOR) || (SHADERPASS == SHADERPASS_DBUFFER_MESH)
				ENCODE_INTO_DBUFFER(surfaceData, outDBuffer);
			#else
				outEmissive.rgb = surfaceData.emissive * GetCurrentExposureMultiplier();
				outEmissive.a = 1.0;
			#endif
			}
            ENDHLSL
        }

		
        Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

            Cull Back

            HLSLPROGRAM
		    #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_ALBEDO
		    #pragma shader_feature_local_fragment _COLORMAP
		    #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_NORMAL
		    #define _MATERIAL_AFFECTS_EMISSION
		    #pragma shader_feature_local_fragment _EMISSIVEMAP
		    #pragma multi_compile _ LOD_FADE_CROSSFADE
		    #pragma shader_feature_local_fragment _MATERIAL_AFFECTS_MASKMAP
		    #pragma shader_feature_local_fragment _MASKMAP
		    #define ASE_SRP_VERSION 140009
		    #define ASE_USING_SAMPLING_MACROS 1

		    #pragma exclude_renderers glcore gles gles3 ps4 ps5 

            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT

			#pragma vertex Vert
			#pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

			// Require _SelectionID variable
            float4 _SelectionID;

           #define SHADERPASS SHADERPASS_DEPTH_ONLY
           #define SCENEPICKINGPASS 1

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/PickingSpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/Decal.hlsl"

            #pragma editor_sync_compilation

			

            struct AttributesMesh
			{
				float3 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryingsToPS
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor_ST;
            float _AntiAlias;
            float _AntiAliasPower;
            float _DrawOrder;
			float _NormalBlendSrc;
			float _MaskBlendSrc;
			float _DecalBlend;
			int   _DecalMeshBiasType;
            float _DecalMeshDepthBias;
			float _DecalMeshViewBias;
            float _DecalStencilWriteMask;
            float _DecalStencilRef;
            #ifdef _MATERIAL_AFFECTS_ALBEDO
            float _AffectAlbedo;
			#endif
            #ifdef _MATERIAL_AFFECTS_NORMAL
            float _AffectNormal;
			#endif
            #ifdef _MATERIAL_AFFECTS_MASKMAP
            float _AffectAO;
			float _AffectMetal;
            float _AffectSmoothness;
			#endif
            #ifdef _MATERIAL_AFFECTS_EMISSION
            float _AffectEmission;
			#endif
            float _DecalColorMask0;
            float _DecalColorMask1;
            float _DecalColorMask2;
            float _DecalColorMask3;
            CBUFFER_END

	   		TEXTURE2D(_BaseColor);
	   		SAMPLER(sampler_BaseColor);


			
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/DecalPrepassBuffer.hlsl"

			PackedVaryingsToPS Vert(AttributesMesh inputMesh )
			{
				PackedVaryingsToPS output;

				UNITY_SETUP_INSTANCE_ID(inputMesh);
				UNITY_TRANSFER_INSTANCE_ID(inputMesh, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				inputMesh.tangentOS = float4( 1, 0, 0, -1);
				inputMesh.normalOS = float3( 0, 1, 0 );

				output.ase_texcoord.xy = inputMesh.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
				float3 defaultVertexValue = inputMesh.positionOS.xyz;
				#else
				float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				inputMesh.positionOS.xyz = vertexValue;
				#else
				inputMesh.positionOS.xyz += vertexValue;
				#endif

				float3 positionRWS = TransformObjectToWorld(inputMesh.positionOS) ;
				output.positionCS = TransformWorldToHClip(positionRWS);

				return output;
			}

			void Frag(  PackedVaryingsToPS packedInput,
						out float4 outColor : SV_Target0
						
						)
			{
				float2 uv_BaseColor = packedInput.ase_texcoord.xy * _BaseColor_ST.xy + _BaseColor_ST.zw;
				float4 tex2DNode5 = SAMPLE_TEXTURE2D( _BaseColor, sampler_BaseColor, uv_BaseColor );
				

				//This port is needed as templates always require fragment ports to correctly work...this will be discarded by the compiler
				float3 baseColor = tex2DNode5.rgb;
				outColor = _SelectionID;
			}

            ENDHLSL
        }
		
    }
    CustomEditor "Rendering.HighDefinition.DecalShaderGraphGUI"
	
	Fallback Off
}
/*ASEBEGIN
Version=19302
Node;AmplifyShaderEditor.FunctionNode;15;-670.1863,107.6941;Inherit;False;Step Antialiasing;-1;;3;2a825e80dfb3290468194f83380797bd;0;2;1;FLOAT;0.54;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-801,105;Inherit;False;Property;_AntiAlias;Anti Alias;1;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-805.8475,324.0381;Inherit;False;Property;_Metallic;Metallic;4;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-670,229;Inherit;False;Property;_AntiAliasPower;Anti Alias Power;2;0;Create;True;0;0;0;False;0;False;-0.32;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;17;-351,32;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-374.8475,413.0381;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;21;-719.8475,485.0381;Inherit;False;Property;_Smoothness;Smoothness;3;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;5;-820.6627,-128.6476;Inherit;True;Property;_BaseColor;Base Color;0;0;Create;True;0;0;0;False;0;False;-1;1e393389fab918548b29dc3c05474be4;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;32;-178.8291,405.3245;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;0,0;Float;False;False;-1;2;Rendering.HighDefinition.DecalShaderGraphGUI;0;1;New Amplify Shader;d345501910c196f4a81c9eff8a0a5ad7;True;DecalProjectorForwardEmissive;0;1;DecalProjectorForwardEmissive;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=HDRenderPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;7;d3d11;metal;vulkan;xboxone;xboxseries;playstation;switch;0;False;True;8;5;False;;1;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;False;False;False;False;False;False;False;True;True;0;True;_DecalStencilRef;255;False;;255;True;_DecalStencilWriteMask;7;False;;3;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;2;False;;False;True;1;LightMode=DecalProjectorForwardEmissive;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;Rendering.HighDefinition.DecalShaderGraphGUI;0;1;New Amplify Shader;d345501910c196f4a81c9eff8a0a5ad7;True;DBufferMesh;0;2;DBufferMesh;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=HDRenderPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;7;d3d11;metal;vulkan;xboxone;xboxseries;playstation;switch;0;False;True;2;5;False;;10;False;;1;0;False;;10;False;;False;False;True;2;5;False;;10;False;;1;0;False;;10;False;;False;False;True;2;5;False;;10;False;;1;0;False;;10;False;;False;False;True;1;0;False;;6;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;0;True;_DecalStencilRef;255;False;;255;True;_DecalStencilWriteMask;7;False;;3;False;;0;False;;0;False;;7;False;;3;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;False;True;1;LightMode=DBufferMesh;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;Rendering.HighDefinition.DecalShaderGraphGUI;0;1;New Amplify Shader;d345501910c196f4a81c9eff8a0a5ad7;True;DecalMeshForwardEmissive;0;3;DecalMeshForwardEmissive;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=HDRenderPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;7;d3d11;metal;vulkan;xboxone;xboxseries;playstation;switch;0;False;True;8;5;False;;1;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;0;True;_DecalStencilRef;255;False;;255;True;_DecalStencilWriteMask;7;False;;3;False;;0;False;;0;False;;7;False;;3;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;False;True;1;LightMode=DecalMeshForwardEmissive;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;Rendering.HighDefinition.DecalShaderGraphGUI;0;1;New Amplify Shader;d345501910c196f4a81c9eff8a0a5ad7;True;ScenePickingPass;0;4;ScenePickingPass;1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=HDRenderPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;7;d3d11;metal;vulkan;xboxone;xboxseries;playstation;switch;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;True;7;d3d11;metal;vulkan;xboxone;xboxseries;playstation;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;30.19999,18.7;Float;False;True;-1;2;Rendering.HighDefinition.DecalShaderGraphGUI;0;14;Amp_Decal;d345501910c196f4a81c9eff8a0a5ad7;True;DBufferProjector;0;0;DBufferProjector;11;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=HDRenderPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;5;True;7;d3d11;metal;vulkan;xboxone;xboxseries;playstation;switch;0;False;True;2;5;False;;10;False;;1;0;False;;10;False;;False;False;True;2;5;False;;10;False;;1;0;False;;10;False;;False;False;True;2;5;False;;10;False;;1;0;False;;10;False;;False;False;True;1;0;False;;6;False;;0;1;False;;0;False;;False;False;False;True;1;False;;False;False;False;False;False;False;False;False;False;True;True;0;True;_DecalStencilRef;255;False;;255;True;_DecalStencilWriteMask;7;False;;3;False;;0;False;;0;False;;7;False;;3;False;;0;False;;0;False;;False;True;2;False;;True;2;False;;False;True;1;LightMode=DBufferProjector;False;False;0;;0;0;Standard;7;Affect BaseColor;1;0;Affect Normal;1;0;Affect Metal;1;638460719729431300;Affect AO;1;0;Affect Smoothness;1;0;Affect Emission;1;0;Support LOD CrossFade;1;0;0;5;True;True;True;True;True;False;;True;0
WireConnection;15;1;16;0
WireConnection;15;2;5;4
WireConnection;17;0;5;4
WireConnection;17;1;15;0
WireConnection;17;2;18;0
WireConnection;30;0;5;4
WireConnection;30;1;21;0
WireConnection;32;0;30;0
WireConnection;0;0;5;0
WireConnection;0;1;17;0
WireConnection;0;2;5;0
WireConnection;0;3;17;0
ASEEND*/
//CHKSM=B89E340A15AE470E4D72A63A61391EF04A84BB90