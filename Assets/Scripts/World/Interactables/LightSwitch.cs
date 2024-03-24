﻿using Entities;
using Interfaces;
using UnityEngine;

namespace World.Interactables
{
    public class LightSwitch : MonoBehaviour, IInteractable
    {
        [SerializeField] private Light light;
        
        public void BeginInteract(BaseEntity entity)
        {
            light.enabled = !light.enabled;
        }
        
        public void EndInteract()
        {
            throw new System.NotImplementedException();
        }
    }
}