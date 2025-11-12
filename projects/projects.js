// ============================================
// IMPORTS
// ============================================
import { fetchJSON } from '../global.js';

// ============================================
// STATE VARIABLES
// ============================================
let projects = await fetchJSON('./projects.json');
// Fix image paths to be relative to this subdirectory
projects = projects.map(p => ({...p, image: '../' + p.image}));
let query = '';
let selectedYears = new Set();
let selectedTags = new Set();

// ============================================
// DOM REFERENCES
// ============================================
const projectsContainer = document.querySelector('.projects');
const searchInput = document.querySelector('.searchBar');
const filterContainer = document.querySelector('.filter-container');
const yearFiltersContainer = document.querySelector('#year-filters');
const tagFiltersContainer = document.querySelector('#tag-filters');
const clearFiltersButton = document.querySelector('.clear-filters');

// ============================================
// INITIALIZATION
// ============================================
initializeFilters();
handleRoute();

// Listen for hash changes (browser back/forward)
window.addEventListener('hashchange', handleRoute);

// ============================================
// ROUTING FUNCTIONS
// ============================================

/**
 * Handle routing based on URL hash
 */
function handleRoute() {
  const hash = window.location.hash.slice(1); // Remove '#'

  if (hash) {
    // Show project detail
    const project = projects.find(p => p.slug === hash);
    if (project) {
      showProjectDetail(project);
    } else {
      // Invalid hash, show grid
      showProjectGrid();
    }
  } else {
    // No hash, show grid
    showProjectGrid();
  }
}

/**
 * Show project grid view
 */
function showProjectGrid() {
  searchInput.style.display = 'block';
  filterContainer.style.display = 'block';
  projectsContainer.className = 'projects';

  const filtered = getFilteredProjects();
  renderProjects(filtered, projectsContainer, 'h2');
}

/**
 * Show project detail view
 */
function showProjectDetail(project) {
  searchInput.style.display = 'none';
  filterContainer.style.display = 'none';
  projectsContainer.className = 'project-detail';

  projectsContainer.innerHTML = `
    <button class="back-button" onclick="window.location.hash = ''">
      ← Back to Projects
    </button>

    <article class="detail-content">
      <h1>${project.title}</h1>

      <div class="detail-meta">
        <span class="year">${project.year}</span>
        ${project.githubUrl ? `<a href="${project.githubUrl}" target="_blank" class="detail-link">View on GitHub</a>` : ''}
        ${project.liveUrl ? `<a href="${project.liveUrl}" target="_blank" class="detail-link">Live Demo</a>` : ''}
      </div>

      <img src="${project.image}" alt="${project.title}" class="detail-image">

      <section class="detail-section">
        <h2>About</h2>
        <p>${project.fullDescription}</p>
      </section>

      <section class="detail-section">
        <h2>Tech Stack</h2>
        <ul class="tech-stack">
          ${project.techStack.map(tech => `<li>${tech}</li>`).join('')}
        </ul>
      </section>

      ${project.challenges ? `
        <section class="detail-section">
          <h2>Challenges</h2>
          <p>${project.challenges}</p>
        </section>
      ` : ''}

      ${project.learnings ? `
        <section class="detail-section">
          <h2>What I Learned</h2>
          <p>${project.learnings}</p>
        </section>
      ` : ''}
      function renderCodeSection(container, project) {
  // Build section shell
  const section = document.createElement('section');
  section.className = 'code-section';
  section.innerHTML = `
    <h2>Code</h2>
    <hr>
    <div class="code-tabs" role="tablist">
      <button class="code-tab" role="tab" aria-selected="true" data-kind="file" data-title="design.sv">design.sv</button>
      <button class="code-tab" role="tab" aria-selected="false" data-kind="file" data-title="testbench.sv">testbench.sv</button>
      <button class="code-tab" role="tab" aria-selected="false" data-kind="file" data-title="output.log">output.log</button>
      <button class="code-tab" role="tab" aria-selected="false" data-kind="image" data-title="EDA Playground Screenshot">EDA Playground Screenshot</button>
    </div>
    <div class="code-view">
      <div class="code-toolbar">
        <div class="code-title"></div>
        <div class="code-actions"><a class="open-raw" href="#" target="_blank" rel="noopener">Open raw</a></div>
      </div>
      <div class="code-pane"></div>
    </div>
  `;
  container.appendChild(section);

  // Elements
  const titleEl = section.querySelector('.code-title');
  const paneEl  = section.querySelector('.code-pane');
  const openEl  = section.querySelector('.open-raw');
  const tabsEl  = section.querySelectorAll('.code-tab');

  // Load text from hidden <script type="text/plain"> blocks
  const DESIGN_SRC = document.getElementById('code-design-sv')?.textContent || '';
  const TB_SRC     = document.getElementById('code-testbench-sv')?.textContent || '';
  const OUTLOG_SRC = document.getElementById('code-output-log')?.textContent || '';

  const esc = (s) => s.replace(/&/g,'&amp;').replace(/</g,'&lt;');

  function codeBlock(text) {
    return `<pre><code>${text.split('\n').map(l=>`<span>${esc(l)}</span>`).join('\n')}</code></pre>`;
  }

  function show(kind, label) {
    titleEl.textContent = label;
    if (kind === 'file' && label === 'design.sv') {
      openEl.href = 'design.sv';
      paneEl.innerHTML = codeBlock(DESIGN_SRC);
    } else if (kind === 'file' && label === 'testbench.sv') {
      openEl.href = 'testbench.sv';
      paneEl.innerHTML = codeBlock(TB_SRC);
    } else if (kind === 'file' && label === 'output.log') {
      openEl.href = 'output.log';
      paneEl.innerHTML = codeBlock(OUTLOG_SRC) +
        `<div class="code-caption"><strong>Tool:</strong> EDA Playground (QuestaSim) · <strong>Run:</strong> run -all · <strong>Tests:</strong> 205 pass / 0 fail · <strong>Coverage:</strong> 89.6% · <strong>Errors/Warnings:</strong> 0 / 1 · <strong>Elapsed:</strong> 1s</div>`;
    } else if (kind === 'image') {
      // Replace with your real image path
      const imgPath = '/assets/images/eda-playground-alu.png';
      openEl.href = imgPath;
      paneEl.innerHTML = `<img class="embed-image" src="${imgPath}" alt="EDA Playground screenshot showing testbench.sv, design.sv, and output log">`;
    }
  }

  tabsEl.forEach(btn => {
    btn.addEventListener('click', () => {
      tabsEl.forEach(b => b.setAttribute('aria-selected','false'));
      btn.setAttribute('aria-selected','true');
      show(btn.dataset.kind, btn.dataset.title);
    });
  });

  // initial
  show('file','design.sv');
}

    </article>
  `;
}

// ============================================
// RENDERING FUNCTIONS
// ============================================

/**
 * Render projects grid with click handlers
 */
function renderProjects(projectsList, containerElement, headingLevel = 'h2') {
  containerElement.innerHTML = '';
  projectsList.forEach((project) => {
    const article = document.createElement('article');
    article.innerHTML = `
      <${headingLevel}>${project.title}</${headingLevel}>
      <img src="${project.image}" alt="${project.title}">
      <div>
        <p>${project.description}</p>
        <p class="year">${project.year}</p>
      </div>
    `;

    // Add click handler to navigate to detail view
    article.style.cursor = 'pointer';
    article.addEventListener('click', () => {
      window.location.hash = project.slug;
    });

    containerElement.appendChild(article);
  });
}

// ============================================
// FILTER FUNCTIONS
// ============================================

/**
 * Initialize filter pills for years and tags
 */
function initializeFilters() {
  // Get unique years and tags
  const years = [...new Set(projects.map(p => p.year))].sort().reverse();
  const allTags = [...new Set(projects.flatMap(p => p.tags || []))].sort();

  // Create year pill buttons
  years.forEach(year => {
    const pill = document.createElement('button');
    pill.className = 'filter-pill';
    pill.textContent = year;
    pill.dataset.value = year;
    pill.dataset.type = 'year';
    pill.addEventListener('click', handlePillClick);
    yearFiltersContainer.appendChild(pill);
  });

  // Create tag pill buttons
  allTags.forEach(tag => {
    const pill = document.createElement('button');
    pill.className = 'filter-pill';
    pill.textContent = tag;
    pill.dataset.value = tag;
    pill.dataset.type = 'tag';
    pill.addEventListener('click', handlePillClick);
    tagFiltersContainer.appendChild(pill);
  });

  clearFiltersButton.addEventListener('click', clearAllFilters);
}

/**
 * Filter projects by search query
 */
function filterByQuery(projectsList) {
  return projectsList.filter((project) => {
    const values = Object.values(project).join(' ').toLowerCase();
    return values.includes(query.toLowerCase());
  });
}

/**
 * Get filtered projects based on query, years, and tags
 */
function getFilteredProjects() {
  let filtered = filterByQuery(projects);

  // Filter by years
  if (selectedYears.size > 0) {
    filtered = filtered.filter(p => selectedYears.has(p.year));
  }

  // Filter by tags (project must have at least one selected tag)
  if (selectedTags.size > 0) {
    filtered = filtered.filter(p =>
      p.tags && p.tags.some(tag => selectedTags.has(tag))
    );
  }

  return filtered;
}

// ============================================
// EVENT HANDLERS
// ============================================

/**
 * Handle pill button clicks
 */
function handlePillClick(event) {
  const pill = event.currentTarget;
  const value = pill.dataset.value;
  const type = pill.dataset.type;

  // Toggle active state
  pill.classList.toggle('active');

  // Update selected filters
  if (type === 'year') {
    if (selectedYears.has(value)) {
      selectedYears.delete(value);
    } else {
      selectedYears.add(value);
    }
  } else if (type === 'tag') {
    if (selectedTags.has(value)) {
      selectedTags.delete(value);
    } else {
      selectedTags.add(value);
    }
  }

  const filtered = getFilteredProjects();
  renderProjects(filtered, projectsContainer, 'h2');
}

/**
 * Clear all filters
 */
function clearAllFilters() {
  selectedYears.clear();
  selectedTags.clear();
  document.querySelectorAll('.filter-pill').forEach(pill => {
    pill.classList.remove('active');
  });
  const filtered = getFilteredProjects();
  renderProjects(filtered, projectsContainer, 'h2');
}

/**
 * Handle search input
 */
searchInput.addEventListener('input', (event) => {
  query = event.target.value;
  const filtered = getFilteredProjects();
  renderProjects(filtered, projectsContainer, 'h2');
});
