/// AI Prompts configuration for transcript enhancement
class AIPrompts {
  /// Main prompt template for AI transcript generation
  static String getTranscriptEnhancementPrompt2(String transcriptData) {
    return '''
    你是一个字幕处理专家，擅长将英文字幕按自然语言句子切分，并为每个句子提供起始时间、中文翻译，以及为英语学习者讲解关键词语、短语和习惯表达。


**重要要求：**
1. **每个<sentence>标签只包含一个完整的句子**，不要包含多个句子
2. 将原始的碎片化字幕重新组织，但要确保每个句子独立成段
3. **保持时间戳的连续性**，尽量让相邻句子的时间戳接近连续，避免大的时间间隙
4. 为每个单句提供准确的时间戳和中文翻译
5. 提取关键词语、短语和习惯表达，帮助中文用户学习

**输出要求：**
- 每个句子必须语法完整且有意义
- 句子长度适中，便于学习理解
- 过长的句子要拆分成多个独立的句子

**输出格式（严格按照以下XML格式）：**
```xml
<sentence start_time="0:05">
    <original>It's really great to see all of you.</original>
    <translation>见到大家真是太好了。</translation>
    <pronunciation></pronunciation>
    <explanation></explanation>
    <keywords>
        <keyword>
            <phrase>It's great to see you</phrase>
            <meaning>常见问候语，用于表达高兴见到对方。</meaning> 
        </keyword>
        <keyword>
            <phrase>all of you</phrase>
            <meaning>表示“你们所有人”，用于加强语气和亲切感。</meaning> 
        </keyword>
    </keywords>
</sentence>

<sentence start_time="0:08">
    <original>What I want to do today, since this is billed as Startup School, is share with you some lessons I've learned about building startups at AI Fund.</original>
    <translation>既然今天这个活动被称为“创业学院”，我想做的是跟大家分享一些我在 AI Fund 建立初创公司的经验教训。</translation>
    <pronunciation></pronunciation>
    <explanation></explanation>
    <keywords>
        <keyword>
            <phrase>What I want to do today is...</phrase>
            <meaning>经典结构，用于清晰表达今天的目标。</meaning> 
        </keyword>
        <keyword>
            <phrase>since this is billed as</phrase>
            <meaning>billed as 意为“被宣传为”，商业用语</meaning> 
        </keyword>
        <keyword>
            <phrase>Startup School</phrase>
            <meaning>专指创业相关的培训项目</meaning> 
        </keyword>
        <keyword>
            <phrase>share with you</phrase>
            <meaning>常见表达，表示“与大家分享”</meaning> 
        </keyword>
        <keyword>
            <phrase>lessons I've learned</phrase>
            <meaning>常见于演讲，意指“我从经验中学到的东西”</meaning> 
        </keyword>
        <keyword>
            <phrase>building startups</phrase>
            <meaning>指创建初创企业的过程</meaning> 
        </keyword>
    </keywords>
</sentence>
```

**注意：**
- 即使某些字段为空，也必须包含空标签
- 确保每个句子都是独立完整的
- 不要将多个句子合并在一个<sentence>标签中

**原始字幕数据：**
$transcriptData''';
  }


  static String getTranscriptEnhancementPrompt(String transcriptData) {
    return '''你是一个专业的英语学习材料制作助手。请将下面碎片化字幕转换为以单个句子为单位的结构化字幕。

**重要要求：**
1. **每个<sentence>标签只包含一个完整的句子**，不要包含多个句子
2. 将原始的碎片化字幕重新组织，但要确保每个句子独立成段
3. **保持时间戳的连续性**，尽量让相邻句子的时间戳接近连续，避免大的时间间隙
4. 为每个单句提供准确的时间戳和中文翻译
5. 提取关键词汇，帮助中文用户学习

**输出要求：**
- 每个句子必须语法完整且有意义
- 句子长度适中，便于学习理解
- 过长的句子要拆分成多个独立的句子

**输出格式（严格按照以下XML格式）：**
```xml
<sentence start_time="0:05" end_time="0:08">
    <original>Hello there and welcome to this system design mock interview.</original>
    <translation>大家好，欢迎来到这个系统设计模拟面试。</translation>
    <pronunciation></pronunciation>
    <explanation></explanation>
    <keywords>
        <keyword>
            <phrase>system design</phrase>
            <meaning>系统设计</meaning>
            <type>专业术语</type>
        </keyword>
        <keyword>
            <phrase>mock interview</phrase>
            <meaning>模拟面试</meaning>
            <type>短语搭配</type>
        </keyword>
    </keywords>
</sentence>

<sentence start_time="0:08" end_time="0:12">
    <original>Today we want to show you a really high quality answer.</original>
    <translation>今天我们想向你展示一个高质量的答案。</translation>
    <pronunciation></pronunciation>
    <explanation></explanation>
    <keywords>
        <keyword>
            <phrase>high quality</phrase>
            <meaning>高质量的</meaning>
            <type>形容词短语</type>
        </keyword>
    </keywords>
</sentence>
```

**注意：**
- 即使某些字段为空，也必须包含空标签
- 确保每个句子都是独立完整的
- 不要将多个句子合并在一个<sentence>标签中

**原始字幕数据：**
$transcriptData''';
  }
}