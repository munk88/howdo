// 站点全局配置：改这里即可换站名 / 作者 / 简介 / 栏目 / 侧栏状态
export const siteConfig = {
  name: '三皮的时光折叠',
  tagline: '记录技术、认知与长期成长',
  author: '三皮',
  avatar: 'https://aka.doubaocdn.com/s/7wNd2zVjtF',
  hero: 'https://aka.doubaocdn.com/s/hGm3ppdDGq',

  // 首页 hero 的三行自我介绍
  intro: [
    '学习一个东西，把它想清楚、做出来，再写下来。',
    '这里记录我在技术实践、认知探索和生活思考中的所得、所思与所做，',
    '希望这些内容，能在未来的某一天对你也有所帮助。'
  ],

  // 座右铭
  motto: { zh: '强观点，弱执着。', en: 'Strong opinions, loosely held.' },

  // 三大栏目（导航 + 首页三栏 + 归档筛选）
  categories: [
    { name: '技术实践', desc: '记录我在网络、系统、工具和项目上的实践与踩坑经验。' },
    { name: '学习与认知', desc: '关于学习方法、知识管理、认知模型与思想探索。' },
    { name: '思考与生活', desc: '关于心理学、个人成长、日常思考与生活记录。' }
  ],

  // 「长期探索的主题」四宫格
  themes: [
    { name: '技术', items: ['网络工程', '系统与工具', '自动化'] },
    { name: '认知', items: ['心理学', '认知模型', '学习方法'] },
    { name: '知识', items: ['阅读', '笔记系统', '知识管理'] },
    { name: '成长', items: ['自我管理', '思考与复盘', '成为更有用的人'] }
  ],

  // 首页「从这里开始」推荐的三篇文章（填 src/content/posts/ 下的文件名）
  featured: ['static-blog', 'zettelkasten', 'walden'],

  // 侧边栏「现在」状态（改成你真实的状态即可）
  now: {
    learning: 'HCIP Datacom',
    researching: 'AI Agent / 心理学 / 认知科学',
    reading: ['《红书》荣格', '《原则》Ray Dalio'],
    thinking: '如何成为一个真正有生产价值的人',
    updated: '2026-09-04'
  },

  // 页脚备案号（填你自己的；没有可留空字符串）
  icp: '沪ICP备XXXXXXXX号'
};
