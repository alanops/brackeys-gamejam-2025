# Performance Optimization Guide

## Overview
This guide covers performance targets and optimization strategies for the Brackeys Game Jam project, focusing on web build constraints and smooth gameplay.

## Performance Targets

### Essential Metrics (Must Hit)
```
FPS:        60+ (stable, no drops)
CPU Time:   < 16ms (for 60 FPS headroom)
Draw Calls: < 1000 (web-friendly)
RAM:        < 100MB (quick loading)
File Size:  < 50MB (itch.io limit)
```

### Detailed Performance Table

| Metric | 🟢 Excellent | 🟡 Acceptable | 🔴 Needs Work | ⛔ Critical |
|--------|--------------|---------------|----------------|-------------|
| **FPS** | 120+ | 60-120 | 30-60 | < 30 |
| **CPU Time** | < 8ms | 8-12ms | 12-16ms | > 16ms |
| **GPU Time** | < 8ms | 8-12ms | 12-16ms | > 16ms |
| **Draw Calls** | < 300 | 300-700 | 700-1500 | > 1500 |
| **RAM Usage** | < 50MB | 50-100MB | 100-200MB | > 200MB |
| **Load Time** | < 3s | 3-5s | 5-10s | > 10s |

## Frame Time Budget

For stable 60 FPS, you have 16.67ms per frame:

```
Total Frame Budget: 16.67ms
├── Game Logic:     5-7ms    (scripts, physics, AI)
├── Rendering:      5-7ms    (drawing, shaders)
└── Safety Buffer:  4-6ms    (for spikes, GC)
```

## Common Performance Issues

### 1. FPS Drops
**Symptoms**: Sudden stuttering, inconsistent frame rate
**Common Causes**:
- Spawning many objects at once
- Complex calculations in _process()
- Garbage collection spikes
- Particle system bursts

**Solutions**:
- Object pooling for bullets/enemies
- Spread calculations across frames
- Pre-instantiate objects
- Limit particle counts

### 2. High CPU Time
**Symptoms**: CPU time > 16ms, game logic bottleneck
**Common Causes**:
- Unoptimized loops
- Too many physics bodies
- Complex AI calculations
- String operations in loops

**Solutions**:
```gdscript
# Bad: Checking every enemy against every bullet
for enemy in enemies:
    for bullet in bullets:
        if enemy.position.distance_to(bullet.position) < 10:
            # collision

# Good: Use physics layers or spatial partitioning
# Let Godot's physics handle collision detection
```

### 3. High Draw Calls
**Symptoms**: Draw calls > 1000, GPU bottleneck
**Common Causes**:
- Many individual sprites
- No texture atlasing
- Unique materials per object
- UI elements not batched

**Solutions**:
- Use MultiMeshInstance for repeated objects
- Combine textures into atlases
- Share materials between objects
- Enable batching in project settings

### 4. Memory Growth
**Symptoms**: RAM usage increasing over time
**Common Causes**:
- Not freeing instances
- Circular references
- Large textures not compressed
- Audio not streamed

**Solutions**:
```gdscript
# Always free unused nodes
queue_free()

# Use weak references for circular dependencies
weakref(object)

# Stream large audio files
AudioStreamPlayer.stream = preload("res://music.ogg")
# Set .ogg import to "Stream"
```

## Web-Specific Optimizations

### File Size Limits
- **Total Build**: < 50MB for itch.io
- **Initial Download**: < 20MB ideal
- **Textures**: Use WebP or compressed PNG
- **Audio**: Ogg Vorbis, low bitrate for SFX

### Browser Constraints
- **Mobile Performance**: Assume 50% desktop speed
- **Memory Limit**: ~200MB before crashes
- **WebGL Limits**: Fewer texture units
- **No Threading**: SingleThreaded performance

### Optimization Checklist
- [ ] Enable texture compression
- [ ] Set audio to appropriate compression
- [ ] Remove unused assets from export
- [ ] Enable GLES3 batching
- [ ] Minimize shader complexity
- [ ] Use LOD for complex models
- [ ] Limit simultaneous sounds

## Quick Wins

### 1. Project Settings
```
Project Settings > Rendering > 
- Textures > Canvas Textures > Default Texture Filter: "Nearest"
- Batching > Use Batching: ON
- Quality > Filters > Use Nearest Mipmap Filter: ON
```

### 2. Import Settings
```
Textures:
- Compress > Mode: "Lossy" or "Lossless"
- Mipmaps > Generate: OFF (for pixel art)

Audio:
- Small SFX: WAV, 22kHz, Mono
- Music: Ogg Vorbis, 128kbps, Stereo
```

### 3. Code Patterns
```gdscript
# Cache references
@onready var player = get_node("Player")

# Use object pooling
var bullet_pool = []

# Avoid per-frame allocations
var reusable_vector = Vector2()

# Use signals over polling
signal.connect(method) # Good
if condition: method() # In _process = Bad
```

## Testing Performance

### In Editor
1. Enable "Project > Project Settings > Debug > Verbose stdout"
2. Run with visible collision shapes
3. Monitor the profiler (Debug > Profiler)
4. Test with target hardware specs

### Web Builds
1. Test in multiple browsers (Chrome, Firefox, Safari)
2. Use browser DevTools Performance tab
3. Test on actual phones/tablets
4. Simulate slow networks

### Performance Testing Checklist
- [ ] Stable 60 FPS in gameplay
- [ ] No memory leaks over 5 minutes
- [ ] Draw calls under limit
- [ ] Load time under 5 seconds
- [ ] Runs on low-end devices
- [ ] No audio crackling
- [ ] Smooth on all target browsers

## Emergency Optimizations

If you're close to submission and need quick fixes:

1. **Reduce Resolution**: `get_window().size = Vector2(960, 540)`
2. **Disable Shadows**: Turn off in DirectionalLight3D
3. **Lower Particle Count**: Halve all particle amounts
4. **Simplify Shaders**: Remove post-processing
5. **Reduce Physics**: Increase physics tick interval
6. **Audio Quality**: Lower bitrate on all sounds
7. **Texture Size**: Batch resize all textures 50%

Remember: **A smooth 30 FPS game is better than a stuttering 60 FPS game!**