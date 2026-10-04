# Motion Canvas API Reference

## Table of Contents

1. [Project & Scene Setup](#project--scene-setup)
2. [Node Types](#node-types)
3. [References](#references)
4. [Signals](#signals)
5. [Flow Control](#flow-control)
6. [Tweening & Animation](#tweening--animation)
7. [Layouts](#layouts)
8. [Camera](#camera)
9. [Transitions](#transitions)
10. [Code Component](#code-component)
11. [Media Components](#media-components)
12. [Transforms](#transforms)
13. [Effects & Filters](#effects--filters)
14. [Custom Components](#custom-components)

---

## Project & Scene Setup

### makeProject

```ts
import {makeProject} from '@motion-canvas/core';
import scene from './scenes/scene?scene';
import audio from './audio/voiceover.mp3';

export default makeProject({
  scenes: [scene1, scene2],  // Array of scenes in order
  audio: audio,              // Optional audio track
  fps: 30,                   // Default: 30
  width: 1920,               // Default: 1920
  height: 1080,              // Default: 1080
});
```

### makeScene2D

```ts
import {makeScene2D} from '@motion-canvas/2d';

export default makeScene2D(function* (view) {
  // view is the root node - add children to it
  view.add(<Circle />);
  view.fill('#1a1a1a');  // Set background color

  // Animation code using yield*
  yield* waitFor(1);
});
```

### vite.config.ts

```ts
import {defineConfig} from 'vite';
import motionCanvas from '@motion-canvas/vite-plugin';
import ffmpeg from '@motion-canvas/ffmpeg';  // Optional: for video export

export default defineConfig({
  plugins: [
    motionCanvas({
      project: './src/project.ts',  // Project file path
      output: './output',           // Export directory
    }),
    ffmpeg(),  // Enable video rendering
  ],
});
```

---

## Node Types

### Shapes

```tsx
// Circle
<Circle
  size={100}           // Diameter (or use width/height)
  fill="#e13238"       // Fill color
  stroke="white"       // Stroke color
  lineWidth={4}        // Stroke width
  startAngle={0}       // Arc start (degrees)
  endAngle={360}       // Arc end (degrees)
  closed={true}        // Close arc path
/>

// Rectangle
<Rect
  width={200}
  height={100}
  fill="blue"
  stroke="white"
  lineWidth={2}
  radius={10}          // Corner radius (or [tl, tr, br, bl])
/>

// Line
<Line
  points={[[0, 0], [100, 50], [200, 0]]}  // Array of points
  stroke="white"
  lineWidth={4}
  lineCap="round"      // "butt" | "round" | "square"
  lineJoin="round"     // "miter" | "round" | "bevel"
  lineDash={[10, 5]}   // Dash pattern
  closed={false}       // Connect last to first point
  startArrow           // Arrow at start
  endArrow             // Arrow at end
  arrowSize={10}       // Arrow size
/>

// Polygon
<Polygon
  sides={6}            // Number of sides
  size={100}           // Circumscribed circle diameter
  fill="green"
/>

// Spline (smooth curve through points)
<Spline
  points={[[0, 0], [100, -50], [200, 0]]}
  stroke="white"
  lineWidth={3}
  smoothness={0.5}     // 0-1, curve smoothness
/>

// Bezier
<Bezier
  p0={[0, 0]}          // Start point
  p1={[50, -100]}      // Control point 1
  p2={[150, -100]}     // Control point 2
  p3={[200, 0]}        // End point
  stroke="white"
  lineWidth={3}
/>
```

### Text

```tsx
<Txt
  text="Hello World"
  fontSize={48}
  fontFamily="Arial"
  fontWeight={700}        // 100-900 or "bold"
  fontStyle="italic"      // "normal" | "italic"
  fill="white"
  textAlign="center"      // "left" | "center" | "right"
  textWrap={true}         // Enable text wrapping
  maxWidth={500}          // Max width for wrapping
  lineHeight={1.5}        // Line height multiplier
  letterSpacing={2}       // Letter spacing in pixels
/>
```

### Generic Node (Container)

```tsx
<Node
  position={[100, 50]}    // [x, y] position
  rotation={45}           // Rotation in degrees
  scale={1.5}             // Scale (or [scaleX, scaleY])
  opacity={0.8}           // 0-1 opacity
  zIndex={10}             // Stacking order
>
  <Circle />
  <Rect />
</Node>
```

---

## References

### createRef

```tsx
import {createRef} from '@motion-canvas/core';

const circle = createRef<Circle>();
view.add(<Circle ref={circle} size={100} />);

// Access node with ()
yield* circle().position.x(300, 1);
circle().fill('#ff0000');
```

### createRefArray

```tsx
import {createRefArray} from '@motion-canvas/core';

const circles = createRefArray<Circle>();
view.add(
  <>
    <Circle ref={circles} />
    <Circle ref={circles} />
    <Circle ref={circles} />
  </>
);

// Access by index
yield* circles[0].scale(2, 1);
// Animate all
yield* all(...circles.map(c => c.opacity(0, 1)));
```

### makeRef (assign to object property)

```tsx
import {makeRef} from '@motion-canvas/core';

const refs: {circle?: Circle; rect?: Rect} = {};
view.add(
  <>
    <Circle ref={makeRef(refs, 'circle')} />
    <Rect ref={makeRef(refs, 'rect')} />
  </>
);
yield* refs.circle.scale(2, 1);
```

---

## Signals

### createSignal

```ts
import {createSignal} from '@motion-canvas/core';

// Simple signal
const count = createSignal(0);
count();      // Read: 0
count(5);     // Write: sets to 5

// Computed signal (lazy, cached)
const doubled = createSignal(() => count() * 2);
doubled();    // 10 (recalculates only when count changes)

// Animate signal
yield* count(10, 2);  // Animate from current to 10 over 2 seconds
```

### Node Properties as Signals

All node properties are signals:

```tsx
const circle = createRef<Circle>();
view.add(<Circle ref={circle} size={100} />);

// Read
const currentSize = circle().size();

// Write (immediate)
circle().fill('#ff0000');

// Animate
yield* circle().size(200, 1);

// Bind to computed value
circle().size(() => count() * 10);
```

### createEffect

```ts
import {createEffect, createDeferredEffect} from '@motion-canvas/core';

// Runs immediately when dependencies change
createEffect(() => {
  console.log('Value changed:', signal());
});

// Runs once per frame even if multiple deps change
createDeferredEffect(() => {
  updateLayout();
});
```

---

## Flow Control

### waitFor / waitUntil

```ts
import {waitFor, waitUntil} from '@motion-canvas/core';

yield* waitFor(2);                    // Wait 2 seconds
yield* waitUntil('event-name');       // Wait until timeline marker
yield* waitUntil('event', [0, 1]);    // Wait until event with offset
```

### useDuration

```ts
import {useDuration} from '@motion-canvas/core';

// Duration controlled by timeline marker in editor
yield* circle().scale(2, useDuration('grow-animation'));
```

### all (parallel)

```ts
import {all} from '@motion-canvas/core';

yield* all(
  circle().position.x(300, 1),
  circle().fill('#ff0000', 1),
  rect().opacity(0, 1),
);
```

### sequence (staggered)

```ts
import {sequence} from '@motion-canvas/core';

// Start each animation 0.1s after previous
yield* sequence(0.1,
  circle1().opacity(1, 0.5),
  circle2().opacity(1, 0.5),
  circle3().opacity(1, 0.5),
);
```

### chain

```ts
import {chain} from '@motion-canvas/core';

// Run in sequence (same as multiple yield*)
yield* chain(
  animation1(),
  animation2(),
  animation3(),
);
```

### loop

```ts
import {loop} from '@motion-canvas/core';

// Loop 5 times
yield* loop(5, i => circle().rotation(360 * (i + 1), 1));

// Infinite loop (use with care)
yield* loop(Infinity, function* () {
  yield* circle().scale(1.2, 0.5).to(1, 0.5);
});
```

### delay

```ts
import {delay} from '@motion-canvas/core';

yield* delay(0.5, circle().opacity(1, 1));  // Wait 0.5s then animate
```

### spawn (non-blocking)

```ts
import {spawn} from '@motion-canvas/core';

spawn(circle().position.x(300, 2));  // Start animation, don't wait
yield* waitFor(1);                    // Continue immediately
// Circle animation continues in background
```

---

## Tweening & Animation

### Property Tweening

```ts
// Basic tween
yield* circle().position.x(300, 1);        // Value, duration

// Chained tweens
yield* circle().position.x(300, 1).to(0, 1).to(-300, 1);

// With easing
yield* circle().scale(2, 1, easeOutBack);

// Vector properties
yield* circle().position([300, 200], 1);   // Animate both x and y
```

### Easing Functions

```ts
import {
  linear,
  easeInQuad, easeOutQuad, easeInOutQuad,
  easeInCubic, easeOutCubic, easeInOutCubic,
  easeInQuart, easeOutQuart, easeInOutQuart,
  easeInBack, easeOutBack, easeInOutBack,    // Overshoot
  easeInElastic, easeOutElastic,              // Bouncy
  easeInBounce, easeOutBounce,                // Bounce
} from '@motion-canvas/core';

yield* circle().scale(2, 1, easeOutBack);
```

### tween (low-level)

```ts
import {tween, map} from '@motion-canvas/core';

yield* tween(2, value => {
  // value goes from 0 to 1 over 2 seconds
  circle().position.x(map(-300, 300, value));
  circle().opacity(value);
});
```

### spring

```ts
import {spring, PlopSpring, BounceSpring, SmoothSpring} from '@motion-canvas/core';

yield* spring(PlopSpring, 0, 100, value => {
  circle().position.y(value);
});
```

### Save & Restore

```ts
circle().save();                    // Save current state
yield* circle().position([300, 200], 1);
yield* circle().fill('#ff0000', 1);
yield* circle().restore(1);         // Animate back to saved state
```

---

## Layouts

### Layout Node

```tsx
<Layout
  layout                    // Enable layout (required)
  direction="row"           // "row" | "column"
  gap={20}                  // Gap between children
  padding={[20, 40]}        // [vertical, horizontal] or single value
  alignItems="center"       // "start" | "center" | "end" | "stretch"
  justifyContent="center"   // "start" | "center" | "end" | "space-between" | "space-around" | "space-evenly"
  wrap="wrap"               // "nowrap" | "wrap" | "wrap-reverse"
>
  <Circle size={50} />
  <Circle size={50} />
</Layout>
```

### Child Layout Properties

```tsx
<Layout layout direction="row">
  <Rect
    width={100}
    height={100}
    grow={1}              // Flex grow
    shrink={0}            // Flex shrink
    basis={100}           // Flex basis
    margin={10}           // Margin around element
    alignSelf="end"       // Override parent alignItems
  />
</Layout>
```

### Cardinal Directions (Positioning)

```tsx
// Position relative to other nodes' edges
<Rect ref={rect1} />
<Rect
  left={rect1().right}           // Left edge at rect1's right
  top={rect1().bottom}           // Top at rect1's bottom
  bottomRight={rect1().topLeft}  // Corner alignment
/>

// Position relative to parent
<Rect topLeft={view.topLeft} />  // Anchor to parent corner
```

---

## Camera

```tsx
import {Camera} from '@motion-canvas/2d';

const camera = createRef<Camera>();

view.add(
  <Camera ref={camera}>
    {/* All scene content inside camera */}
    <Circle />
    <Rect />
  </Camera>
);

// Camera animations
yield* camera().position([100, 50], 1);   // Pan
yield* camera().zoom(2, 1);                // Zoom in
yield* camera().rotation(45, 1);           // Rotate view
yield* camera().centerOn(circle(), 1);     // Focus on node
yield* camera().reset(1);                  // Reset all transforms
```

---

## Transitions

```ts
import {
  slideTransition,
  fadeTransition,
  zoomInTransition,
  zoomOutTransition,
  useTransition,
  Direction,
} from '@motion-canvas/core';

// At start of scene
yield* slideTransition(Direction.Left, 1);
yield* fadeTransition(0.5);
yield* zoomInTransition();

// Custom transition
const endTransition = useTransition(
  ctx => ctx.globalAlpha = 0,  // Modify current scene
  ctx => {},                    // Modify previous scene
);
yield* all(/* animations */);
endTransition();
```

---

## Code Component

```tsx
import {Code, LezerHighlighter} from '@motion-canvas/2d';
import {parser} from '@lezer/javascript';

// Set up syntax highlighting
Code.defaultHighlighter = new LezerHighlighter(
  parser.configure({dialect: 'jsx ts'})
);

const codeRef = createRef<Code>();
view.add(
  <Code
    ref={codeRef}
    code={`const x = 1;`}
    fontSize={24}
    fontFamily="Fira Code"
  />
);

// Replace entire code
yield* codeRef().code(`const y = 2;`, 1);

// Replace specific range
const range = codeRef().findFirstRange('x');
yield* codeRef().code.replace(range, 'newValue', 0.5);

// Insert code
yield* codeRef().code.insert([0, 10], 'inserted text', 0.5);

// Append code
yield* codeRef().code.append('\n// comment', 0.5);

// Highlight selection
yield* codeRef().selection(codeRef().findFirstRange('const'), 0.5);

// Clear selection
import {DEFAULT} from '@motion-canvas/core';
yield* codeRef().selection(DEFAULT, 0.3);
```

---

## Media Components

### Images

```tsx
import imageSrc from './images/photo.png';

<Img
  src={imageSrc}
  width={400}              // Scale to width
  height={300}             // Scale to height
  // or use scale
  scale={0.5}
/>
```

### Video

```tsx
import videoSrc from './videos/clip.mp4';

const video = createRef<Video>();
view.add(
  <Video
    ref={video}
    src={videoSrc}
    width={800}
    loop                    // Loop playback
  />
);

video().play();             // Start playback
video().pause();            // Pause
video().seek(5);            // Seek to 5 seconds
yield* video().scale(1.5, 1);  // Animate while playing
```

### Audio

```ts
// In project.ts
import audio from './audio/voiceover.mp3';

export default makeProject({
  scenes: [scene],
  audio: audio,  // Syncs with timeline
});
```

---

## Transforms

### Position

```tsx
// Relative to parent (local space)
node.position([100, 50]);
node.position.x(100);
node.position.y(50);

// Absolute (world space)
node.absolutePosition([100, 50]);
```

### Scale

```tsx
node.scale(2);              // Uniform scale
node.scale([2, 1.5]);       // Non-uniform [x, y]
node.scale.x(2);
node.absoluteScale(2);      // World space scale
```

### Rotation

```tsx
node.rotation(45);          // Degrees
node.absoluteRotation(45);  // World space
```

### Coordinate Conversion

```tsx
// Convert between coordinate spaces
const worldPos = node.localToWorld();      // Local to world matrix
const localPos = node.worldToLocal();      // World to local matrix
const parentPos = node.localToParent();    // Local to parent matrix
```

---

## Effects & Filters

### Filters

```tsx
// On node
<Circle filters.blur={10} filters.brightness={1.2} />

// Animate
yield* circle().filters.blur(10, 1);
yield* circle().filters.grayscale(1, 1);
yield* circle().filters.saturate(0, 1);
yield* circle().filters.sepia(1, 1);
yield* circle().filters.hueRotate(180, 1);
yield* circle().filters.contrast(2, 1);
```

### Composite Operations

```tsx
<Circle compositeOperation="screen" />
// Options: "source-over", "multiply", "screen", "overlay", etc.
```

### Shadows

```tsx
<Rect
  shadowColor="rgba(0,0,0,0.5)"
  shadowBlur={10}
  shadowOffset={[5, 5]}
/>
```

### Clipping

```tsx
<Rect clip width={200} height={200}>
  <Circle size={300} />  {/* Clipped to parent bounds */}
</Rect>
```

---

## Custom Components

```tsx
import {Node, NodeProps, initial, signal} from '@motion-canvas/2d';
import {SimpleSignal, SignalValue} from '@motion-canvas/core';

export interface MyComponentProps extends NodeProps {
  value?: SignalValue<number>;
}

export class MyComponent extends Node {
  @initial(0)
  @signal()
  public declare readonly value: SimpleSignal<number, this>;

  public constructor(props?: MyComponentProps) {
    super(props);

    // Build component tree
    this.add(
      <Rect fill={() => this.value() > 50 ? 'green' : 'red'}>
        <Txt text={() => `${this.value()}`} />
      </Rect>
    );
  }

  // Custom animation method
  public *animateValue(target: number, duration: number) {
    yield* this.value(target, duration);
  }
}

// Usage
const comp = createRef<MyComponent>();
view.add(<MyComponent ref={comp} value={25} />);
yield* comp().animateValue(100, 2);
```

---

## Scene Queries

```ts
import {is} from '@motion-canvas/2d';

// Find all nodes of type
const allCircles = view.findAll(is(Circle));
const firstRect = view.findFirst(is(Rect));

// Find by condition
const largeNodes = view.findAll(node => node.scale.x() > 1);

// Direct children only
const childRects = container().children().filter(is(Rect));
```

---

## Presentation Mode

```ts
import {beginSlide} from '@motion-canvas/core';

yield* beginSlide('introduction');
// Content for slide 1
yield* waitFor(1);

yield* beginSlide('main-content');
// Content for slide 2

// Navigate slides with spacebar in Presentation Mode
```
