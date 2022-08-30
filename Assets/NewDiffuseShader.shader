Shader "Unlit/NewDiffuseShader" //folder, and name
{
    Properties  //variables that are used to modify material
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Gloss("Gloss", float) = 1
        _SpecIntense("Speculation Intensity ", float) = 1
    }
    SubShader   //most of the subshader code we will go to
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"} //this tells unity giving different type of property to shaders
        LOD 100 //level of detail 100, higher more details, if mobile game, lower this

        Pass    //shader pass, shaders can have multiple shader passes
        {
            CGPROGRAM   //we are doing cgprogram, CG functions, its what directX uses
            #pragma vertex vert     //vertex shader, run on every single vert
            #pragma fragment frag   //fragment shader

            #include "UnityCG.cginc"    //its like a global include file
            #include "UnityLightingCommon.cginc"

            //float4 is the hight level of precision in terms of property   //32 bits
            //fixed 11 bits, basic colors, good for hat
            //half 16 bits

            struct appdata  //appdata, object or mesh data. material is attached to the mesh itself.
            {
                float4 vertex : POSITION;   
                float2 uv : TEXCOORD0;  //this uv data is only used for texture sampling //texcoord, is shaders way of passsing data from vertex to fragment, from appdata to vertex
                float3 normal : NORMAL;
            };

            struct v2f //this is vert to frag, this just waterfalls all the way to the fragment shader at the bottom. it's passing vertex data, to frag
            {
                float2 uv : TEXCOORD0;  //texcoord have limitations to this, certain ios devices, have only a limited amount of texcoords. There's ten of them
                float4 vertex : SV_POSITION;   //this is cause of some devices like ps4, POSITION didnt work and they had to put SV Position, but now all devices can handle SV_POsition
                float3 normal : TEXCOORD1;
                float3 viewDirect : TEXCOORD2;
            };

            sampler2D _MainTex; //for texture sampling
            float4 _MainTex_ST;
            float _Gloss, _SpecIntense;

            v2f vert (appdata v)    //it takes in appdata    ran in every single verticies
            {
                v2f o;  //unity calls it o, because output.
                o.vertex = UnityObjectToClipPos(v.vertex);  //assigning the vertex here, its usually in object space and we need to transform it to clip space(world Space)
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);   //It scales and offsets texture coordinates. XY values controls the texture tiling and ZW the offset.
                o.normal = UnityObjectToWorldNormal(v.normal);//this is doing a matrix multiply, to calculate normal from object space, so we have to convert it to worldspace

                o.viewDirect = normalize(WorldSpaceViewDir(v.vertex));  //return the vertex that is towards the camera, it needs to be normalize cause later the math requires it to be normalized.

                return o;
            }

            fixed4 frag (v2f i) : SV_Target //fragment is run on every single pixel on screen //sv target is telling the fragment shader we have one color for output
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float nDot = max(0, dot(i.normal, _WorldSpaceLightPos0.xyz));    //we put max, we want to make sure it goes to negative and if it does go to negative, it clamps it to 0
                float3 lighting = nDot * _LightColor0 + ShadeSH9(float4(i.normal, 1));  ////shading the spherical harmonics

                //so we wanna calculate our reflected light, to get our specular color
                float3 reflecLight = reflect(_WorldSpaceLightPos0.xyz, i.normal);
                //but to get our spec we need to do a dot product, with our view direct,and reflected light vector
                float speculation = max(0, dot(reflecLight, i.viewDirect));    //adding max so we dont go to -1, so clamp it at 0, 1
                float3 finalSpec = pow(speculation, _Gloss) * _SpecIntense * _LightColor0;  //we have to multiply the spec color with light color in order for us to

                float3 finalColor = col * lighting * finalSpec;
                return fixed4(1, 2, 3, 1); //for it to allow textures, i will need to multiply col, by it, and since its a
            }
            ENDCG
        }
    }
}
