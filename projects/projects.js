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

      ${
        // Only show the Code section for your ALU project.
        // Right now your ALU project has slug "multimodal-rag-system" in projects.json.
        project.slug === 'multimodal-rag-system'
          ? `
        <section class="detail-section">
          <h2>Code</h2>

          <div class="code-tabs" role="tablist">
            <button class="code-tab" role="tab" aria-selected="true" data-kind="file" data-title="design.sv">
              design.sv
            </button>
            <button class="code-tab" role="tab" aria-selected="false" data-kind="file" data-title="testbench.sv">
              testbench.sv
            </button>
            <button class="code-tab" role="tab" aria-selected="false" data-kind="file" data-title="output.log">
              output.log
            </button>
            <button class="code-tab" role="tab" aria-selected="false" data-kind="image" data-title="EDA Playground Screenshot">
              EDA Playground Screenshot
            </button>
          </div>

          <div class="code-wrap">
            <div class="code-bar">
              <div class="code-title" id="alu-title">design.sv</div>
              <div class="code-actions">
                <a id="alu-open" href="#" download>Open raw</a>
              </div>
            </div>
            <div class="code-pane" id="alu-pane"></div>
          </div>
        </section>
      `
          : ''
      }
    </article>
  `;

  // Initialize the ALU code viewer only for that one project
  if (project.slug === 'multimodal-rag-system') {
    initALUCodeTabs();
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

// ============================================
// ALU PROJECT - CODE VIEWER
// ============================================

// Raw sources (used only for the ALU project)
// Using String.raw so we don't have to escape backslashes.
const ALU_DESIGN_SRC = String.raw`//===========================
// design.sv  (RTL)
//===========================
package alu_pkg;
  typedef enum logic [2:0] {
    ALU_ADD = 3'd0, ALU_SUB = 3'd1, ALU_AND = 3'd2,
    ALU_OR  = 3'd3, ALU_XOR = 3'd4, ALU_SLT = 3'd5
  } alu_op_e;
endpackage

module alu #(parameter int WIDTH = 32)(
  input  logic             clk,
  input  logic             rst_n,
  // request
  input  logic             req_valid,
  output logic             req_ready,
  input  logic [WIDTH-1:0] a,
  input  logic [WIDTH-1:0] b,
  input  alu_pkg::alu_op_e op,
  // response
  output logic             rsp_valid,
  output logic [WIDTH-1:0] result,
  output logic             zero,
  output logic             neg,
  output logic             ovf,
  output logic             carry
);
  import alu_pkg::*;
  assign req_ready = 1'b1;   // always ready for simplicity

  // Latch request, respond next cycle (1-cycle pipeline)
  logic [WIDTH-1:0] a_q, b_q;
  alu_op_e          op_q;
  logic             taken_d;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_q <= '0; b_q <= '0; op_q <= ALU_ADD;
      taken_d  <= 1'b0;
      rsp_valid<= 1'b0;
    end else begin
      taken_d <= (req_valid && req_ready); // remember taken request
      if (req_valid && req_ready) begin
        a_q <= a; b_q <= b; op_q <= op;
      end
      rsp_valid <= taken_d; // drive response the FOLLOWING cycle
    end
  end

  // Core datapath (combinational on registered inputs)
  logic signed [WIDTH-1:0] a_s, b_s;
  assign a_s = a_q; assign b_s = b_q;

  logic [WIDTH:0] add_full, sub_full;
  assign add_full = {1'b0,a_q} + {1'b0,b_q};
  assign sub_full = {1'b0,a_q} - {1'b0,b_q};

  logic [WIDTH-1:0] result_c;
  logic             ovf_c, carry_c;

  always_comb begin
    result_c = '0; ovf_c = 1'b0; carry_c = 1'b0;
    unique case (op_q)
      ALU_ADD: begin
        result_c = add_full[WIDTH-1:0];
        carry_c  = add_full[WIDTH];
        ovf_c    = (a_q[WIDTH-1]==b_q[WIDTH-1]) && (result_c[WIDTH-1]!=a_q[WIDTH-1]);
      end
      ALU_SUB: begin
        result_c = sub_full[WIDTH-1:0];
        carry_c  = ~sub_full[WIDTH]; // "not borrow" as carry
        ovf_c    = (a_q[WIDTH-1]!=b_q[WIDTH-1]) && (result_c[WIDTH-1]!=a_q[WIDTH-1]);
      end
      ALU_AND: result_c = a_q & b_q;
      ALU_OR : result_c = a_q | b_q;
      ALU_XOR: result_c = a_q ^ b_q;
      ALU_SLT: result_c = {{(WIDTH-1){1'b0}}, (a_s < b_s)};
      default: result_c = '0;
    endcase
  end

  assign result = result_c;
  assign zero   = (result_c == '0);
  assign neg    =  result_c[WIDTH-1];
  assign ovf    = ovf_c;
  assign carry  = carry_c;
endmodule`;

const ALU_TB_SRC = String.raw`//===========================
// testbench.sv
//===========================
\`timescale 1ns/1ps
import alu_pkg::*;  // uses alu_op_e from design.sv

module testbench;
  // ---- Clock / reset ----
  logic clk = 0; always #5 clk = ~clk;   // 100 MHz
  logic rst_n;

  // ---- DUT I/O ----
  logic         req_valid, req_ready;
  logic [31:0]  a, b, result;
  alu_op_e      op;
  logic         rsp_valid, zero, neg, ovf, carry;

  // ---- DUT instance (design.sv unchanged) ----
  alu dut (
    .clk(clk), .rst_n(rst_n),
    .req_valid(req_valid), .req_ready(req_ready),
    .a(a), .b(b), .op(op),
    .rsp_valid(rsp_valid), .result(result),
    .zero(zero), .neg(neg), .ovf(ovf), .carry(carry)
  );

  // ---- Tiny functional coverage ----
  alu_op_e     cov_op;
  logic [31:0] cov_a, cov_b;
  logic        cov_ovf;

  covergroup cg_ops_sign_ovf;
    option.per_instance = 1;
    cp_op:   coverpoint cov_op  { bins add={ALU_ADD}; bins sub={ALU_SUB};
                                  bins andb={ALU_AND}; bins orb={ALU_OR};
                                  bins xorb={ALU_XOR}; bins slt={ALU_SLT}; }
    cp_sign: coverpoint {cov_a[31], cov_b[31]} {
              bins pp={2'b00}; bins pn={2'b01}; bins np={2'b10}; bins nn={2'b11}; }
    cp_ovf:  coverpoint cov_ovf { bins no={0}; bins yes={1}; }
    x_all:   cross cp_op, cp_sign, cp_ovf;
  endgroup
  cg_ops_sign_ovf cg = new();

  // ---- Simple golden reference model ----
  function automatic void ref_model(
    input  logic [31:0] ia, ib, input alu_op_e iop,
    output logic [31:0] o_res,
    output logic o_zero, o_neg, o_ovf, o_carry
  );
    logic [32:0] add_full = {1'b0,ia} + {1'b0,ib};
    logic [32:0] sub_full = {1'b0,ia} - {1'b0,ib};
    o_res='0; o_ovf=0; o_carry=0;
    unique case (iop)
      ALU_ADD: begin
        o_res   = add_full[31:0];
        o_carry = add_full[32];
        o_ovf   = ((ia[31]==ib[31]) && (o_res[31]!=ia[31]));
      end
      ALU_SUB: begin
        o_res   = sub_full[31:0];
        o_carry = ~sub_full[32]; // not-borrow
        o_ovf   = ((ia[31]!=ib[31]) && (o_res[31]!=ia[31]));
      end
      ALU_AND: o_res = ia & ib;
      ALU_OR : o_res = ia | ib;
      ALU_XOR: o_res = ia ^ ib;
      ALU_SLT: o_res = {{31{1'b0}}, $signed(ia) < $signed(ib)};
      default: o_res = '0;
    endcase
    o_zero = (o_res=='0);
    o_neg  =  o_res[31];
  endfunction

  // ---- Drive + check helper (no SVA, no timing drama) ----
  int unsigned pass_cnt=0, fail_cnt=0;

  task automatic do_op(input logic [31:0] ia, ib, input alu_op_e iop);
    logic [31:0] exp_res; logic exp_zero, exp_neg, exp_ovf, exp_carry;
    // Pulse request for 1 cycle
    @(posedge clk); a<=ia; b<=ib; op<=iop; req_valid<=1'b1;
    @(posedge clk); req_valid<=1'b0;
    // Wait for response pulse (DUT is single-cycle, this is safe/portable)
    wait (rsp_valid == 1'b1);
    // Compare with golden
    ref_model(ia, ib, iop, exp_res, exp_zero, exp_neg, exp_ovf, exp_carry);
    if (result !== exp_res)       begin $error("RES %h vs %h", result, exp_res); fail_cnt++; end
    else if (zero   !== exp_zero) begin $error("ZERO mismatch");               fail_cnt++; end
    else if (neg    !== exp_neg)  begin $error("NEG  mismatch");               fail_cnt++; end
    else if (ovf    !== exp_ovf)  begin $error("OVF  mismatch");               fail_cnt++; end
    else if (carry  !== exp_carry)begin $error("CARRY mismatch");              fail_cnt++; end
    else pass_cnt++;
    // Sample coverage
    cov_a=ia; cov_b=ib; cov_op=iop; cov_ovf=ovf; cg.sample();
  endtask

  // ---- Test sequence ----
  initial begin
    // Reset
    rst_n=0; req_valid=0; a='0; b='0; op=ALU_ADD;
    repeat (5) @(posedge clk); rst_n=1;

    // Directed edge cases
    do_op(32'h7FFF_FFFF, 32'h0000_0001, ALU_ADD); // +ovf
    do_op(32'h8000_0000, 32'h0000_0001, ALU_SUB); // -ovf
    do_op(32'hDEAD_BEEF, 32'hDEAD_BEEF, ALU_XOR); // zero
    do_op(32'hFFFF_FFFE, 32'h0000_0001, ALU_SLT); // signed less
    do_op(32'h0000_0000, 32'hFFFF_FFFF, ALU_AND); // logic

    // Random sweep
    repeat (200) begin
      alu_op_e r; r = alu_op_e'(\$urandom_range(0,5));
      do_op(\$urandom, \$urandom, r);
    end

    // Summary
    \$display("\\nAll tests finished. Pass=%0d, Fail=%0d, Coverage=%.1f%%",
             pass_cnt, fail_cnt, cg.get_coverage());
    \$finish;
  end
endmodule`;

const ALU_OUTLOG_SRC = String.raw`QuestaSim-64 qrun 2024.3_1 Utility 2024.10 Oct 17 2024
Start time: 19:09:23 on Nov 11,2025
qrun -batch -access=rw+/. -uvmhome uvm-1.2 -timescale 1ns/1ns -mfcu design.sv testbench.sv -voptargs="+acc=npr" -do " run -all; exit"
Creating library 'qrun.out/work'.
Mapping library 'mtiUvm' to 'qrun.out/work'.
QuestaSim-64 vlog 2024.3_1 Compiler 2024.10 Oct 17 2024
Start time: 19:09:24 on Nov 11,2025
-- Compiling package uvm_pkg (uvm-1.2 Built-in)
-- Compiling package questa_uvm_pkg
-- Importing package uvm_pkg (uvm-1.2 Built-in)
-- Compiling package alu_pkg
-- Compiling module alu
-- Importing package alu_pkg
-- Compiling package uvm_pkg_sv_unit
-- Importing package alu_pkg
-- Compiling module testbench

Top level modules:
	testbench
-- Compiling DPI/PLI C++ file /usr/share/questa/questasim/verilog_src/uvm-1.2/src/dpi/uvm_dpi.cc

End time: 19:09:26 on Nov 11,2025, Elapsed time: 0:00:02
Errors: 0, Warnings: 0
QuestaSim-64 vopt 2024.3_1 Compiler 2024.10 Oct 17 2024
** Warning: (vopt-10587) Some optimizations are turned off because the +acc switch is in effect. This will cause your simulation to run slowly. Please use -access/-debug to maintain needed visibility. The +acc switch would be deprecated in a future release.
Start time: 19:09:26 on Nov 11,2025
vopt -access=rw+/. -timescale 1ns/1ns -mfcu "+acc=npr" -findtoplevels qrun.out/work+1+ -work qrun.out/work -statslog qrun.out/stats_log -csession=incr -o qrun_opt -csessionid=2

Top level modules:
	testbench

Analyzing design...
-- Loading module testbench
-- Loading module alu
Optimizing 4 design-units (inlining 0/2 module instances):
-- Optimizing package alu_pkg(fast)
-- Optimizing package uvm_pkg_sv_unit(fast)
-- Optimizing module testbench(fast)
-- Optimizing module alu(fast)
Optimized design name is qrun_opt
End time: 19:09:26 on Nov 11,2025, Elapsed time: 0:00:00
Errors: 0, Warnings: 1
# vsim -batch -lib qrun.out/work -do " run -all; exit" -statslog qrun.out/stats_log qrun_opt -appendlog -l qrun.log
# Start time: 19:09:27 on Nov 11,2025
# Loading /tmp/unknown@7bbc97b2a77b_dpi_50/linux_x86_64_gcc-10.3.0/export_tramp.so
# //  Questa Sim-64
# //  Version 2024.3_1 linux_x86_64 Oct 17 2024
# //
# // Unpublished work. Copyright 2024 Siemens
# //
# // This material contains trade secrets or otherwise confidential information
# // owned by Siemens Industry Software Inc. or its affiliates (collectively,
# // "SISW"), or its licensors. Access to and use of this information is strictly
# // limited as set forth in the Customer's applicable agreements with SISW.
# //
# // This material may not be copied, distributed, or otherwise disclosed outside
# // of the Customer's facilities without the express written permission of SISW,
# // and may not be used in any way not expressly authorized by SISW.
# //
# Loading sv_std.std
# Loading work.alu_pkg(fast)
# Loading work.uvm_pkg_sv_unit(fast)
# Loading work.testbench(fast)
# Loading work.alu(fast)
# Loading /tmp/unknown@7bbc97b2a77b_dpi_50/linux_x86_64_gcc-10.3.0/vsim_auto_compile.so
#
# run -all
#
# All tests finished. Pass=205, Fail=0, Coverage=89.6%
# ** Note: $finish    : testbench.sv(118)
#    Time: 6195 ns  Iteration: 2  Instance: /testbench
# End time: 19:09:28 on Nov 11,2025, Elapsed time: 0:00:01
# Errors: 0, Warnings: 0
End time: 19:09:28 on Nov 11,2025, Elapsed time: 0:00:05
*** Summary *********************************************
    qrun: Errors:   0, Warnings:   0
    vlog: Errors:   0, Warnings:   0
    vopt: Errors:   0, Warnings:   1
    vsim: Errors:   0, Warnings:   0
  Totals: Errors:   0, Warnings:   1`;

function initALUCodeTabs() {
  const pane  = document.getElementById('alu-pane');
  const title = document.getElementById('alu-title');
  const open  = document.getElementById('alu-open');
  const tabs  = document.querySelectorAll('.code-tab');

  if (!pane || !title || !open || !tabs.length) return;

  const esc = (s) =>
    s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

  function codeBlock(text) {
    const lines = text.split('\n');
    const htmlLines = lines
      .map(line => `<span>${esc(line)}</span>`)
      .join('\n');
    return `<pre class="code-pre"><code>${htmlLines}</code></pre>`;
  }

  function render(kind, label) {
    title.textContent = label;

    if (kind === 'file' && label === 'design.sv') {
      pane.innerHTML = codeBlock(ALU_DESIGN_SRC);
      open.href = '#';
      open.download = 'design.sv';
    } else if (kind === 'file' && label === 'testbench.sv') {
      pane.innerHTML = codeBlock(ALU_TB_SRC);
      open.href = '#';
      open.download = 'testbench.sv';
    } else if (kind === 'file' && label === 'output.log') {
      pane.innerHTML =
        codeBlock(ALU_OUTLOG_SRC) +
        `<div class="code-caption">
          <strong>Tool:</strong> QuestaSim via EDA Playground ·
          <strong>Run:</strong> run -all ·
          <strong>Tests:</strong> 205 pass / 0 fail ·
          <strong>Coverage:</strong> 89.6% ·
          <strong>Errors/Warnings:</strong> 0 / 1
        </div>`;
      open.href = '#';
      open.download = 'output.log';
    } else if (kind === 'image') {
      // Update this path to wherever you save the screenshot in your repo
      pane.innerHTML = `
        <img
          class="embed-image"
          src="../images/eda-playground-alu.png"
          alt="EDA Playground screenshot showing design.sv, testbench.sv, and output log"
        />
      `;
      open.href = '../images/eda-playground-alu.png';
      open.removeAttribute('download');
    }
  }

  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      tabs.forEach(b => b.setAttribute('aria-selected', 'false'));
      btn.setAttribute('aria-selected', 'true');
      render(btn.dataset.kind, btn.dataset.title);
    });
  });

  // Initial view
  render('file', 'design.sv');
}
