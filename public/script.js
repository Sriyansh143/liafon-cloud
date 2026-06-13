// ===================================
// Liafon Cloud - Interactive JavaScript
// ===================================

document.addEventListener('DOMContentLoaded', () => {
    
    // Tab Switching Functionality
    const tabButtons = document.querySelectorAll('.tab-btn');
    const tabPanels = document.querySelectorAll('.tab-panel');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const targetTab = button.getAttribute('data-tab');
            
            // Remove active class from all buttons and panels
            tabButtons.forEach(btn => btn.classList.remove('active'));
            tabPanels.forEach(panel => panel.classList.remove('active'));
            
            // Add active class to clicked button and corresponding panel
            button.classList.add('active');
            document.getElementById(targetTab).classList.add('active');
        });
    });
    
    // Dark Mode Toggle
    const darkModeToggle = document.getElementById('darkModeToggle');
    const htmlElement = document.documentElement;
    
    // Check for saved theme preference
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
        htmlElement.setAttribute('data-theme', 'dark');
        if (darkModeToggle) darkModeToggle.checked = true;
    }
    
    if (darkModeToggle) {
        darkModeToggle.addEventListener('change', () => {
            if (darkModeToggle.checked) {
                htmlElement.setAttribute('data-theme', 'dark');
                localStorage.setItem('theme', 'dark');
            } else {
                htmlElement.removeAttribute('data-theme');
                localStorage.setItem('theme', 'light');
            }
        });
    }
    
    // Smooth Scroll for Navigation Links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            if (targetId !== '#') {
                const targetElement = document.querySelector(targetId);
                if (targetElement) {
                    const navHeight = document.querySelector('.navbar').offsetHeight;
                    const targetPosition = targetElement.offsetTop - navHeight;
                    
                    window.scrollTo({
                        top: targetPosition,
                        behavior: 'smooth'
                    });
                }
            }
        });
    });
    
    // Navbar Scroll Effect
    let lastScroll = 0;
    const navbar = document.querySelector('.navbar');
    
    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;
        
        if (currentScroll > 100) {
            navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
        } else {
            navbar.style.boxShadow = 'none';
        }
        
        lastScroll = currentScroll;
    });
    
    // Mobile Menu Toggle
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
    const navLinks = document.querySelector('.nav-links');
    const navActions = document.querySelector('.nav-actions');
    
    if (mobileMenuBtn) {
        mobileMenuBtn.addEventListener('click', () => {
            mobileMenuBtn.classList.toggle('active');
            
            // Create or toggle mobile menu
            let mobileMenu = document.querySelector('.mobile-menu');
            
            if (!mobileMenu) {
                mobileMenu = document.createElement('div');
                mobileMenu.className = 'mobile-menu';
                mobileMenu.innerHTML = `
                    <ul class="nav-links-mobile"></ul>
                    <div class="nav-actions-mobile"></div>
                `;
                
                // Clone nav links
                const navLinksClone = navLinks.cloneNode(true);
                navLinksClone.className = 'nav-links-mobile';
                mobileMenu.querySelector('.nav-links-mobile').replaceWith(navLinksClone);
                
                // Clone nav actions
                const navActionsClone = navActions.cloneNode(true);
                navActionsClone.className = 'nav-actions-mobile';
                mobileMenu.querySelector('.nav-actions-mobile').replaceWith(navActionsClone);
                
                navbar.appendChild(mobileMenu);
            }
            
            mobileMenu.classList.toggle('active');
        });
    }
    
    // Intersection Observer for Animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observe feature cards
    document.querySelectorAll('.feature-card, .download-card, .doc-card').forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = 'all 0.6s ease';
        observer.observe(card);
    });
    
    // Animated Counter for Stats
    const animateCounter = (element, target, duration = 2000) => {
        let start = 0;
        const increment = target / (duration / 16);
        
        const updateCounter = () => {
            start += increment;
            if (start < target) {
                if (target >= 1000) {
                    element.textContent = Math.floor(start).toLocaleString() + '+';
                } else if (target % 1 !== 0) {
                    element.textContent = start.toFixed(1);
                } else {
                    element.textContent = Math.floor(start);
                }
                requestAnimationFrame(updateCounter);
            } else {
                if (target >= 1000) {
                    element.textContent = target.toLocaleString() + '+';
                } else {
                    element.textContent = target;
                }
            }
        };
        
        updateCounter();
    };
    
    // Trigger counter animation when stats are visible
    const statsObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const statValues = entry.target.querySelectorAll('.stat-value');
                statValues.forEach(stat => {
                    const text = stat.textContent;
                    if (text.includes('10K')) {
                        animateCounter(stat, 10000);
                    } else if (text.includes('4.9')) {
                        stat.textContent = '★ 4.9';
                    } else if (text.includes('100%')) {
                        stat.textContent = '100%';
                    }
                });
                statsObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });
    
    const heroStats = document.querySelector('.hero-stats');
    if (heroStats) {
        statsObserver.observe(heroStats);
    }
    
    // Workout Button Selection
    const workoutButtons = document.querySelectorAll('.workout-btn');
    workoutButtons.forEach(button => {
        button.addEventListener('click', () => {
            workoutButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
        });
    });
    
    // Pulse Animation for Heart Rate
    const pulseWave = document.querySelector('.pulse-wave path');
    if (pulseWave) {
        let offset = 0;
        const animatePulse = () => {
            offset = (offset + 1) % 100;
            // Could add more sophisticated animation here
            requestAnimationFrame(animatePulse);
        };
        // animatePulse(); // Uncomment for continuous animation
    }
    
    // Parallax Effect for Hero Background
    const heroBgEffects = document.querySelector('.hero-bg-effects');
    if (heroBgEffects) {
        window.addEventListener('scroll', () => {
            const scrolled = window.pageYOffset;
            const glows = heroBgEffects.querySelectorAll('.glow');
            glows.forEach((glow, index) => {
                const speed = 0.1 + (index * 0.05);
                glow.style.transform = `translateY(${scrolled * speed}px)`;
            });
        });
    }
    
    // Form Validation (if forms are added later)
    const validateEmail = (email) => {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    };
    
    // Add loading state to buttons on click
    document.querySelectorAll('.btn').forEach(button => {
        button.addEventListener('click', function(e) {
            if (this.getAttribute('href') && this.getAttribute('href').startsWith('#')) {
                return;
            }
            
            // Only add loading state for external links/downloads
            if (!this.classList.contains('btn-secondary')) {
                // Commented out to prevent actual loading state on demo
                // this.classList.add('loading');
                // setTimeout(() => this.classList.remove('loading'), 2000);
            }
        });
    });
    
    // Tooltip functionality (can be extended)
    const createTooltip = (element, text) => {
        const tooltip = document.createElement('div');
        tooltip.className = 'tooltip';
        tooltip.textContent = text;
        element.appendChild(tooltip);
        
        element.addEventListener('mouseenter', () => {
            tooltip.style.opacity = '1';
            tooltip.style.visibility = 'visible';
        });
        
        element.addEventListener('mouseleave', () => {
            tooltip.style.opacity = '0';
            tooltip.style.visibility = 'hidden';
        });
    };
    
    // Console welcome message
    console.log('%c🚀 Liafon Cloud - Smartwatch Companion App', 'font-size: 20px; font-weight: bold; color: #6366f1;');
    console.log('%cBuilt with ❤️ as open source', 'font-size: 14px; color: #6b7280;');
    console.log('%cContributions welcome! Check out our GitHub repository.', 'font-size: 12px; color: #9ca3af;');
    
});

// Service Worker Registration (for PWA support)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        // Uncomment below when you have a service worker file
        // navigator.serviceWorker.register('/sw.js')
        //     .then(registration => {
        //         console.log('ServiceWorker registration successful');
        //     })
        //     .catch(err => {
        //         console.log('ServiceWorker registration failed: ', err);
        //     });
    });
}

// Export for potential module usage
export {};
