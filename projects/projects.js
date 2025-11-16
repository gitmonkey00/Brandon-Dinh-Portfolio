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
 * Async to support loading external source files
 */
async function handleRoute() {
  const hash = window.location.hash.slice(1); // Remove '#'

  if (hash) {
    // Show project detail
    const project = projects.find(p => p.slug === hash);
    if (project) {
      await showProjectDetail(project);
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
 * Loads source files asynchronously if they exist
 */
async function showProjectDetail(project) {
  searchInput.style.display = 'none';
  filterContainer.style.display = 'none';
  projectsContainer.className = 'project-detail';

  // Load source files if they exist (with paths)
  let sourceFilesContent = null;
  if (project.sourceFiles && project.sourceFiles.length > 0) {
    // Check if source files have paths (external files) or code (inline)
    if (project.sourceFiles[0].path) {
      sourceFilesContent = await loadSourceFiles(project.sourceFiles);
    } else {
      // Use inline code if available (backward compatibility)
      sourceFilesContent = project.sourceFiles;
    }
  }

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

      ${sourceFilesContent ? renderCodeViewer(sourceFilesContent) : ''}

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

    </article>
  `;

  // Attach event listeners for code viewer tabs if source files exist
  if (sourceFilesContent) {
    attachCodeViewerListeners();
  }
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
// SOURCE FILE LOADING
// ============================================

/**
 * Load source files from external paths
 * Fetches file content asynchronously from the server
 * @param {Array} sourceFiles - Array of source file objects with filename, language, and path
 * @returns {Promise<Array>} Array of source file objects with code content
 */
async function loadSourceFiles(sourceFiles) {
  const loadedFiles = [];

  for (const file of sourceFiles) {
    const isImage = file.language === 'image';

    if (isImage) {
      loadedFiles.push({
        filename: file.filename,
        language: file.language,
        code: '',
        path: file.path,
        isImage: true
      });
      continue;
    }

    try {
      // Fetch file content from the path
      const response = await fetch(file.path);
      if (!response.ok) {
        throw new Error(`Failed to load ${file.filename}: ${response.status}`);
      }
      const code = await response.text();

      // Create file object with loaded code
      loadedFiles.push({
        filename: file.filename,
        language: file.language,
        code: code,
        path: file.path
      });
    } catch (error) {
      console.error(`Error loading ${file.filename}:`, error);
      // Add placeholder for failed file
      loadedFiles.push({
        filename: file.filename,
        language: file.language,
        code: `// Error loading file: ${error.message}`,
        path: file.path
      });
    }
  }

  return loadedFiles;
}

// ============================================
// CODE VIEWER FUNCTIONS
// ============================================

/**
 * Apply basic syntax highlighting to code
 * Supports SystemVerilog/Verilog keywords and common patterns
 * @param {string} code - Raw source code
 * @param {string} language - Programming language (e.g., 'systemverilog')
 * @returns {string} HTML with syntax highlighting
 */
function applySyntaxHighlighting(code, language) {
  let highlighted = code;

  // Escape HTML special characters first
  highlighted = highlighted
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');

  if (language === 'systemverilog' || language === 'verilog') {
    // SystemVerilog/Verilog keywords
    const keywords = [
      'module', 'endmodule', 'input', 'output', 'logic', 'wire', 'reg',
      'parameter', 'localparam', 'typedef', 'enum', 'struct', 'union',
      'always_comb', 'always_ff', 'always_latch', 'always', 'initial',
      'case', 'endcase', 'if', 'else', 'for', 'while', 'begin', 'end',
      'function', 'endfunction', 'task', 'endtask', 'class', 'endclass',
      'package', 'endpackage', 'interface', 'endinterface', 'modport',
      'clocking', 'endclocking', 'property', 'endproperty', 'assert',
      'assign', 'return', 'import', 'export', 'rand', 'randc',
      'constraint', 'inside', 'default'
    ];

    // Highlight keywords
    keywords.forEach(keyword => {
      const regex = new RegExp(`\\b(${keyword})\\b`, 'g');
      highlighted = highlighted.replace(regex, '<span class="syntax-keyword">$1</span>');
    });

    // Highlight types
    const types = ['int', 'bit', 'byte', 'string', 'void', 'automatic'];
    types.forEach(type => {
      const regex = new RegExp(`\\b(${type})\\b`, 'g');
      highlighted = highlighted.replace(regex, '<span class="syntax-type">$1</span>');
    });

    // Highlight comments (single-line)
    highlighted = highlighted.replace(
      /(\/\/.*?)(&lt;|$)/g,
      '<span class="syntax-comment">$1</span>$2'
    );

    // Highlight strings
    highlighted = highlighted.replace(
      /"([^"\\]|\\.)*"/g,
      '<span class="syntax-string">$&</span>'
    );

    // Highlight numbers (including hex and binary)
    highlighted = highlighted.replace(
      /\b(\d+'[hbdo][0-9a-fA-F_]+|\d+)\b/g,
      '<span class="syntax-number">$1</span>'
    );
  }

  return highlighted;
}

/**
 * Render code viewer with tabs for multiple source files
 * @param {Array} sourceFiles - Array of source file objects with filename, language, and code
 * @returns {string} HTML for code viewer section
 */
function renderCodeViewer(sourceFiles) {
  if (!sourceFiles || sourceFiles.length === 0) {
    return '';
  }

  // Generate tabs HTML
  const tabsHTML = sourceFiles.map((file, index) => `
    <button class="code-tab-button ${index === 0 ? 'active' : ''}"
            data-tab-index="${index}">
      ${file.filename}
    </button>
  `).join('');

  // Generate tab content HTML
  const tabContentsHTML = sourceFiles.map((file, index) => {
    const isImage = file.isImage || file.language === 'image';
    let contentHTML = '';

    if (isImage) {
      const imageSrc = file.path || file.code;
      contentHTML = `
        <div class="code-display image-display">
          <img src="${imageSrc}" alt="${file.filename}">
        </div>
      `;
    } else {
      const lines = (file.code || '').split('\n');
      const highlightedLines = lines.map((line, lineNum) => {
        const highlighted = applySyntaxHighlighting(line, file.language);
        return `<span class="code-line"><span class="line-number">${lineNum + 1}</span><span class="line-content">${highlighted}</span></span>`;
      }).join('\n');

      contentHTML = `
        <div class="code-display">
          <pre>${highlightedLines}</pre>
        </div>
      `;
    }

    return `
      <div class="code-tab-content ${index === 0 ? 'active' : ''}"
           data-tab-index="${index}">
        ${contentHTML}
      </div>
    `;
  }).join('');

  return `
    <section class="detail-section">
      <h2>Source Code</h2>
      <div class="code-viewer-container">
        <div class="code-tabs">
          ${tabsHTML}
        </div>
        ${tabContentsHTML}
      </div>
    </section>
  `;
}

/**
 * Attach event listeners to code viewer tab buttons
 * Enables switching between different source files
 */
function attachCodeViewerListeners() {
  const tabButtons = document.querySelectorAll('.code-tab-button');

  tabButtons.forEach(button => {
    button.addEventListener('click', (e) => {
      const tabIndex = e.currentTarget.dataset.tabIndex;

      // Remove active class from all buttons and contents
      document.querySelectorAll('.code-tab-button').forEach(btn => {
        btn.classList.remove('active');
      });
      document.querySelectorAll('.code-tab-content').forEach(content => {
        content.classList.remove('active');
      });

      // Add active class to clicked button and corresponding content
      e.currentTarget.classList.add('active');
      document.querySelector(`.code-tab-content[data-tab-index="${tabIndex}"]`)
        .classList.add('active');
    });
  });
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
