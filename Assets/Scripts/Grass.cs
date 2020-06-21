using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Grass : MonoBehaviour
{
    public Gradient m_GrassColor;

    public Material m_GrassMaterial;

    private Texture2D m_Texture;

    void Awake()
    {
        m_Texture = new Texture2D(128, 1, TextureFormat.ARGB32, false);

        m_Texture.filterMode = FilterMode.Point;

        CreatetColorTexture();
    }

    // Update is called once per frame
    void Update()
    {
        if (m_GrassMaterial)
        {
            m_GrassMaterial.SetTexture("_GrassColorTex", m_Texture);

        }
    }

    void CreatetColorTexture()
	{
        float width = m_Texture.width;
        float height = m_Texture.height;

        float inv = 1f / (width - 1);

        for (int y = 0; y < height; y++)
		{
            for (int x = 0; x < width; x++)
			{
                var t = x * inv;
                Color col = m_GrassColor.Evaluate(t);
                m_Texture.SetPixel(x, y, col);
			}
		}

        m_Texture.Apply();

        if (m_GrassMaterial)
		{
            m_GrassMaterial.SetTexture("_GrassColorTex", m_Texture);

        }
	}

#if UNITY_EDITOR
    void OnValidate()
	{
        if (!m_Texture)
        {
            m_Texture = new Texture2D(128, 1, TextureFormat.ARGB32, false);
            
            m_Texture.filterMode = FilterMode.Point;
        }
        
        CreatetColorTexture();
	}
#endif
}
