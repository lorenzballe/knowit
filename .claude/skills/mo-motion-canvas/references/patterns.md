# Motion Canvas Patterns & Examples

## Table of Contents

1. [Animation Presets](#animation-presets)
2. [Multiple Objects](#multiple-objects)
3. [Data Visualization](#data-visualization)
4. [Text Animations](#text-animations)
5. [Code Walkthroughs](#code-walkthroughs)
6. [Layout Animations](#layout-animations)
7. [Audio Synchronization](#audio-synchronization)
8. [Reusable Components](#reusable-components)

---

## Animation Presets

### Slide In/Out

```ts
export function* slideInFromBottom(node: Node, duration = 0.5) {
  const targetPos = node.position();
  node.position([targetPos.x, targetPos.y + 200]);
  node.opacity(0);
  yield* all(
    node.position(targetPos, duration, easeOutCubic),
    node.opacity(1, duration * 0.8),
  );
}

export function* slideOutToBottom(node: Node, duration = 0.5) {
  const startPos = node.position();
  yield* all(
    node.position([startPos.x, startPos.y + 200], duration, easeInCubic),
    node.opacity(0, duration * 0.8),
  );
}

// Usage
yield* slideInFromBottom(circle());
yield* waitFor(1);
yield* slideOutToBottom(circle());
```

### Zoom In/Out

```ts
export function* zoomIn(node: Node, duration = 0.5) {
  node.scale(0);
  node.opacity(0);
  yield* all(
    node.scale(1, duration, easeOutBack),
    node.opacity(1, duration * 0.8),
  );
}

export function* zoomOut(node: Node, duration = 0.5) {
  yield* all(
    node.scale(0, duration, easeInBack),
    node.opacity(0, duration * 0.8),
  );
}
```

### Fade With Scale

```ts
export function* fadeInWithScale(node: Node, duration = 0.5) {
  node.opacity(0);
  node.scale(0.8);
  yield* all(
    node.opacity(1, duration),
    node.scale(1, duration, easeOutCubic),
  );
}
```

### Bounce/Pop Effect

```ts
export function* popIn(node: Node, duration = 0.6) {
  node.scale(0);
  yield* node.scale(1.2, duration * 0.6, easeOutCubic);
  yield* node.scale(1, duration * 0.4, easeInOutCubic);
}

export function* bounce(node: Node, height = 50, duration = 0.4) {
  const startY = node.position.y();
  yield* node.position.y(startY - height, duration / 2, easeOutCubic);
  yield* node.position.y(startY, duration / 2, easeInCubic);
}
```

---

## Multiple Objects

### Staggered Entrance

```tsx
const items = createRefArray<Circle>();

view.add(
  <Layout layout direction="row" gap={20}>
    {range(5).map(i => (
      <Circle ref={items} size={50} fill="#e13238" opacity={0} scale={0} />
    ))}
  </Layout>
);

// Staggered animation
for (let i = 0; i < items.length; i++) {
  yield* all(
    items[i].opacity(1, 0.3),
    items[i].scale(1, 0.3, easeOutBack),
  );
  yield* waitFor(0.1);  // Stagger delay
}

// Or use sequence
yield* sequence(0.1,
  ...items.map(item => all(item.opacity(1, 0.3), item.scale(1, 0.3)))
);
```

### Animate All Simultaneously

```tsx
yield* all(...items.map(item => item.fill('#00ff00', 1)));
```

### Wave Animation

```tsx
yield* loop(3, function* () {
  for (let i = 0; i < items.length; i++) {
    spawn(items[i].position.y(-30, 0.2).to(0, 0.2));
    yield* waitFor(0.05);
  }
  yield* waitFor(0.5);
});
```

---

## Data Visualization

### Animated Bar Chart

```tsx
const data = [30, 70, 45, 90, 60];
const bars = createRefArray<Rect>();
const maxHeight = 300;

view.add(
  <Layout layout direction="row" gap={20} alignItems="end">
    {data.map((value, i) => (
      <Rect
        ref={bars}
        width={50}
        height={0}
        fill="#e13238"
        radius={[5, 5, 0, 0]}
      />
    ))}
  </Layout>
);

// Animate bars growing
yield* sequence(0.1,
  ...data.map((value, i) =>
    bars[i].height((value / 100) * maxHeight, 0.5, easeOutCubic)
  )
);
```

### Animated Counter

```tsx
const count = createSignal(0);

view.add(
  <Txt
    text={() => Math.round(count()).toLocaleString()}
    fontSize={72}
    fill="white"
  />
);

yield* count(1000, 2);  // Count from 0 to 1000 over 2 seconds
```

### Pie/Donut Chart

```tsx
const values = [30, 25, 20, 15, 10];
const colors = ['#e13238', '#3498db', '#2ecc71', '#f39c12', '#9b59b6'];
const arcs = createRefArray<Circle>();

let startAngle = 0;
view.add(
  <>
    {values.map((value, i) => {
      const angle = (value / 100) * 360;
      const arc = (
        <Circle
          ref={arcs}
          size={300}
          fill="transparent"
          stroke={colors[i]}
          lineWidth={60}
          startAngle={startAngle}
          endAngle={startAngle}  // Start at 0 arc
        />
      );
      startAngle += angle;
      return arc;
    })}
  </>
);

// Animate each arc
startAngle = 0;
for (let i = 0; i < values.length; i++) {
  const angle = (values[i] / 100) * 360;
  yield* arcs[i].endAngle(startAngle + angle, 0.5, easeOutCubic);
  startAngle += angle;
}
```

---

## Text Animations

### Typewriter Effect

```tsx
const text = createSignal('');
const fullText = 'Hello, World!';

view.add(<Txt text={text} fontSize={48} fill="white" />);

for (let i = 0; i <= fullText.length; i++) {
  text(fullText.slice(0, i));
  yield* waitFor(0.05);
}
```

### Word-by-Word Reveal

```tsx
const words = 'This is a sentence'.split(' ');
const wordRefs = createRefArray<Txt>();

view.add(
  <Layout layout direction="row" gap={15}>
    {words.map(word => (
      <Txt ref={wordRefs} text={word} fontSize={48} fill="white" opacity={0} />
    ))}
  </Layout>
);

for (const word of wordRefs) {
  yield* word.opacity(1, 0.3);
  yield* waitFor(0.2);
}
```

### Text Highlight

```tsx
const textRef = createRef<Txt>();
view.add(<Txt ref={textRef} text="Important text here" fontSize={48} fill="white" />);

// Highlight effect
yield* textRef().fill('#ffff00', 0.3);
yield* waitFor(1);
yield* textRef().fill('white', 0.3);
```

---

## Code Walkthroughs

### Progressive Code Reveal

```tsx
const code = createRef<Code>();
view.add(<Code ref={code} code="" fontSize={24} />);

// Add code line by line
yield* code().code(`const x = 1;`, 0.5);
yield* waitFor(0.5);
yield* code().code.append(`\nconst y = 2;`, 0.5);
yield* waitFor(0.5);
yield* code().code.append(`\nconst sum = x + y;`, 0.5);
```

### Code Transformation

```tsx
const code = createRef<Code>();
view.add(
  <Code
    ref={code}
    code={`function add(a, b) {
  return a + b;
}`}
    fontSize={24}
  />
);

yield* waitFor(1);

// Transform to arrow function
yield* code().code(`const add = (a, b) => a + b;`, 1);
```

### Highlight and Explain

```tsx
const code = createRef<Code>();

// Highlight specific part
const range = code().findFirstRange('return');
yield* code().selection(range, 0.3);

// Show explanation
const explanation = createRef<Txt>();
view.add(<Txt ref={explanation} text="Returns the sum" opacity={0} y={200} />);
yield* explanation().opacity(1, 0.3);

yield* waitFor(2);

// Clear
yield* all(
  code().selection(DEFAULT, 0.3),
  explanation().opacity(0, 0.3),
);
```

---

## Layout Animations

### Dynamic List

```tsx
const container = createRef<Layout>();
const items: Rect[] = [];

view.add(
  <Layout ref={container} layout direction="column" gap={10} />
);

// Add items dynamically
for (let i = 0; i < 5; i++) {
  const item = <Rect width={200} height={50} fill="#e13238" opacity={0} />;
  items.push(item as Rect);
  container().add(item);
  yield* (item as Rect).opacity(1, 0.3);
  yield* waitFor(0.2);
}

// Remove items
for (const item of [...items].reverse()) {
  yield* item.opacity(0, 0.3);
  item.remove();
  yield* waitFor(0.1);
}
```

### Expanding/Collapsing Panel

```tsx
const panel = createRef<Rect>();
const content = createRef<Layout>();

view.add(
  <Rect ref={panel} width={300} height={50} fill="#333" clip>
    <Layout ref={content} layout direction="column" padding={20}>
      <Txt text="Header" fill="white" />
      <Txt text="Hidden content line 1" fill="white" />
      <Txt text="Hidden content line 2" fill="white" />
    </Layout>
  </Rect>
);

// Expand
yield* panel().height(200, 0.5, easeOutCubic);

// Collapse
yield* panel().height(50, 0.5, easeInCubic);
```

---

## Audio Synchronization

### Event-Based Timing

```ts
// In scene file
yield* introAnimation();
yield* waitUntil('section-1');  // Marker in editor timeline

yield* section1Animation();
yield* waitUntil('section-2');

yield* section2Animation();
```

### Duration-Based Sync

```ts
// Duration controlled by timeline markers
yield* circle().scale(2, useDuration('scale-up'));
yield* circle().position.x(300, useDuration('move-right'));
```

### Combining Events and Animations

```ts
// Start animation, then wait for audio cue
spawn(backgroundAnimation());
yield* waitUntil('narrator-starts');
yield* textReveal();
```

---

## Reusable Components

### Card Component

```tsx
interface CardProps extends RectProps {
  title: string;
  content: string;
}

export function Card({title, content, ...props}: CardProps) {
  return (
    <Rect
      fill="#2d2d2d"
      stroke="#555"
      lineWidth={2}
      radius={12}
      padding={20}
      layout
      direction="column"
      gap={10}
      {...props}
    >
      <Txt text={title} fontSize={24} fontWeight={700} fill="white" />
      <Txt text={content} fontSize={16} fill="#ccc" />
    </Rect>
  );
}

// Usage
view.add(<Card title="My Card" content="Card content here" width={300} />);
```

### Animated Icon Component

```tsx
export class AnimatedIcon extends Node {
  @signal()
  public declare readonly active: SimpleSignal<boolean, this>;

  private circle = createRef<Circle>();

  public constructor(props?: NodeProps) {
    super(props);
    this.add(
      <Circle
        ref={this.circle}
        size={50}
        fill={() => this.active() ? '#2ecc71' : '#e74c3c'}
      />
    );
  }

  public *toggle(duration = 0.3) {
    yield* this.circle().scale(1.2, duration / 2);
    this.active(!this.active());
    yield* this.circle().scale(1, duration / 2);
  }
}

// Usage
const icon = createRef<AnimatedIcon>();
view.add(<AnimatedIcon ref={icon} active={false} />);
yield* icon().toggle();
```

### Scene Template

```tsx
// scenes/template.tsx
export default makeScene2D(function* (view) {
  // Background
  view.fill('#1a1a1a');

  // Title
  const title = createRef<Txt>();
  view.add(
    <Txt
      ref={title}
      text="Scene Title"
      fontSize={72}
      fill="white"
      y={-300}
      opacity={0}
    />
  );

  // Content area
  const content = createRef<Layout>();
  view.add(
    <Layout
      ref={content}
      layout
      direction="column"
      gap={20}
      opacity={0}
    />
  );

  // Intro animation
  yield* fadeTransition(0.5);
  yield* title().opacity(1, 0.5);
  yield* content().opacity(1, 0.5);

  // Main content animations
  yield* waitUntil('content-start');
  // ... content animations

  // Outro
  yield* waitUntil('scene-end');
  yield* all(
    title().opacity(0, 0.5),
    content().opacity(0, 0.5),
  );
});
```

---

## Best Practices

1. **Use refs for animated nodes** - Always create refs for nodes you'll animate
2. **Prefer `all()` for parallel animations** - More efficient than spawning multiple tasks
3. **Use `sequence()` for staggered effects** - Cleaner than manual delay loops
4. **Keep scenes focused** - One concept per scene, use transitions between
5. **Use time events for audio sync** - `waitUntil()` allows timeline adjustment without code changes
6. **Extract reusable animations** - Create generator functions for common patterns
7. **Use computed signals** - For values that depend on other animated values
8. **Test with hot reload** - Motion Canvas updates instantly on save
